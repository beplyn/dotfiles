{
  config,
  lib,
  pkgs,
  subst,
  username,
  ...
}:

# k3s workloads, one manifest each in ./k8s with @var@s filled in from here.
# nginx reaches them on NodePorts bound to loopback only; data lands on k3s.storage
let
  cfg = config.k3s;
  st = cfg.storage;
  # every workload runs as this uid where its image allows it
  uid = 3000;

  # tmpfiles entries; "v" is a btrfs subvolume (a plain dir elsewhere)
  own = type: mode: user: group: path: "${type} ${path} ${mode} ${user} ${group} -";
  app = own "d" "0750" (toString uid) (toString uid);
  root = own "d" "0700" "root" "root";
  subvol = own "v" "0755" username "users";
  # snapper keeps its snapshots in here
  snapshots = path: own "v" "0750" "root" "root" "${path}/.snapshots";

  # host: subdomain (null: not proxied), port: NodePort, body: nginx upload limit
  # (Cloudflare caps a request at 100m anyway), secrets: random keys in the
  # Secret named like the app, dirs: what the pods mount, extra: more manifests
  apps = { };

  enabled = lib.filterAttrs (n: _: lib.elem n cfg.apps) apps;
  proxied = lib.filterAttrs (_: a: a ? host) enabled;

  fqdn = a: "${a.host}.${config.proxy.domain}";

  vars =
  {
    domain = config.proxy.domain;
    tz = config.time.timeZone;
    inherit uid;
    render = config.ids.gids.render;
    gpu = cfg.gpuResource;
    inherit (st) state cache scratch bulk;
  }
  # every app's, so gatus and glance can list the others
  // lib.concatMapAttrs (n: a: lib.optionalAttrs (a ? host)
  {
    "${n}.host" = fqdn a;
    "${n}.port" = a.port;
  }) apps;

  manifest = name: pkgs.writeText "${name}.yaml" (subst vars (builtins.readFile ./k8s/${name}.yaml));
  manifests = lib.unique (lib.concatLists (lib.mapAttrsToList (n: a: [ n ] ++ a.extra or [ ]) enabled));

  secretSpec = pkgs.writeText "k3s-app-secrets" (lib.concatStrings (lib.mapAttrsToList
    (n: a: lib.optionalString (a ? secrets) "${n} ${n} ${lib.concatStringsSep " " a.secrets}\n")
    enabled));

  dirRules = pkgs.writeText "k3s-app-dirs.conf" (lib.concatLines
    ([ (root st.state) ] ++ lib.concatLists (lib.mapAttrsToList (_: a: a.dirs or [ ]) enabled)));
in
{
  options.k3s =
  {
    apps = lib.mkOption
    {
      type = lib.types.listOf (lib.types.enum (lib.attrNames apps));
      default = [ ];
      example = [ "vaultwarden" "jellyfin" ];
      description = "Workloads to run on k3s, each proxied at its subdomain of proxy.domain.";
    };

    gpuResource = lib.mkOption
    {
      type = lib.types.str;
      default = "gpu.intel.com/i915";
      example = "gpu.intel.com/xe";
      description = "Device plugin resource Jellyfin asks for: i915 for Arc A-series, xe for B-series.";
    };

    storage =
    {
      state = lib.mkOption
      {
        type = lib.types.str;
        default = "/srv/apps";
        description = "Small, hot app state and databases; the system SSD.";
      };
      cache = lib.mkOption
      {
        type = lib.types.str;
        default = "/srv/cache";
        description = "Regenerable, read-mostly caches: thumbnails, metadata, ML models.";
      };
      scratch = lib.mkOption
      {
        type = lib.types.str;
        default = "/srv/scratch";
        description = "Write-heavy throwaway data: transcodes, encoded video.";
      };
      bulk = lib.mkOption
      {
        type = lib.types.str;
        default = "/srv/tank";
        description = "Irreplaceable bulk data: music, video, photos, documents.";
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.apps != [ ])
  {
    assertions =
    [
      {
        assertion = config.proxy.enable;
        message = "k3s.apps are reached through nginx: enable proxy";
      }
    ];

    services.k3s =
    {
      # nginx proxies to them; nothing on the LAN gets around it
      extraFlags = [ "--kube-proxy-arg=nodeport-addresses=127.0.0.0/8" ];
      manifests = lib.listToAttrs (map (name:
      {
        name = "app-${name}";
        value.source = manifest name;
      }) manifests);
    };

    proxy.hosts = lib.mapAttrs' (_: a: lib.nameValuePair a.host
    {
      inherit (a) port;
      maxBodySize = a.body or null;
    }) proxied;

    # created only with every disk mounted: pods mount hostPath type Directory, so a
    # missing disk stops them instead of letting them fill the system SSD
    systemd.services.k3s-app-dirs =
    {
      wantedBy = [ "k3s.service" ];
      before = [ "k3s.service" ];
      unitConfig.RequiresMountsFor = [ st.state st.cache st.scratch st.bulk ];
      serviceConfig =
      {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${config.systemd.package}/bin/systemd-tmpfiles --create ${dirRules}";
      };
    };

    # random passwords and keys, generated in the cluster, never in the store or git
    systemd.services.k3s-app-secrets =
    {
      wantedBy = [ "multi-user.target" ];
      wants = [ "k3s.service" ];
      after = [ "k3s.service" ];
      path = [ config.services.k3s.package pkgs.openssl pkgs.coreutils ];
      serviceConfig =
      {
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0077";
        TimeoutStartSec = "6min";
        ExecStart = "${pkgs.bash}/bin/bash ${./k8s/secrets.sh} ${secretSpec}";
      };
    };
  };
}
