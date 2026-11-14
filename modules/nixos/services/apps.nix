{
  config,
  lib,
  pkgs,
  subst,
  username,
  email,
  ...
}:

# k3s workloads, one manifest each in ./k8s with @var@s filled in from here.
# nginx reaches them on NodePorts bound to loopback only; data lands on k3s.storage
let
  cfg = config.k3s;
  st = cfg.storage;
  # every workload runs as this uid where its image allows it
  uid = 3000;
  alertTopic = "alerts";

  # tmpfiles entries; "v" is a btrfs subvolume (a plain dir elsewhere)
  own = type: mode: user: group: path: "${type} ${path} ${mode} ${user} ${group} -";
  app = own "d" "0750" (toString uid) (toString uid);
  root = own "d" "0700" "root" "root";
  subvol = own "v" "0755" username "users";

  # host: subdomain (unset: not proxied), port: NodePort, body: nginx upload limit
  # (Cloudflare caps a request at 100m; the LAN has none), secrets: generated keys in the
  # Secret named like the app (see k8s/secrets.sh), dirs: what the pods mount,
  # extra: more manifests, lan: host ports open to the LAN, postgres: what to pg_dumpall,
  # oidc: takes Pocket ID credentials from k8s/oidc/<app>.sealed.yaml, oidcVars: @vars@
  # that depend on whether that file exists
  apps =
  {
    vaultwarden =
    {
      host = "vault";
      port = 30080;
      body = "100m";
      secrets = [ "ADMIN_TOKEN" ];
      dirs = [ (app "${st.state}/vaultwarden") ];
      oidc = true;
    };
    forgejo =
    {
      host = "git";
      port = 30030;
      body = "100m";
      secrets = [ "SECRET_KEY" "INTERNAL_TOKEN" "ADMIN_PASSWORD" ];
      # app.ini lives in data/custom/conf
      dirs =
      [
        (app "${st.state}/forgejo")
        (app "${st.state}/forgejo/data")
      ];
      # git over ssh, LAN only: Cloudflare doesn't proxy it
      lan.tcp = [ 2222 ];
      oidc = true;
    };
    gatus =
    {
      host = "status";
      port = 30081;
      dirs = [ (app "${st.state}/gatus") ];
    };
    glance =
    {
      host = "home";
      port = 30082;
    };
    pocket-id =
    {
      host = "id";
      port = 30141;
      secrets = [ "ENCRYPTION_KEY" ];
      dirs = [ (app "${st.state}/pocket-id") ];
    };
    # LAN DNS, nothing to proxy
    blocky =
    {
      lan =
      {
        tcp = [ 53 ];
        udp = [ 53 ];
      };
    };
    # admin is you; beacon is the publish-only user the host's failure alerts use
    ntfy =
    {
      host = "ntfy";
      port = 30083;
      secrets =
      [
        "ADMIN_PASSWORD"
        "ADMIN_HASH=bcrypt:ADMIN_PASSWORD"
        "ALERT_PASSWORD"
        "ALERT_HASH=bcrypt:ALERT_PASSWORD"
        "ALERT_TOKEN=ntfy-token"
      ];
      dirs = [ (app "${st.state}/ntfy") ];
    };
    miniflux =
    {
      host = "rss";
      port = 30084;
      secrets = [ "POSTGRES_PASSWORD" "ADMIN_PASSWORD" ];
      dirs =
      [
        (app "${st.state}/miniflux")
        (app "${st.state}/miniflux/postgres")
      ];
      postgres =
      {
        deployment = "miniflux-db";
        user = "miniflux";
      };
      oidc = true;
      oidcVars = on: { provider = if on then "oidc" else ""; };
    };
    paperless =
    {
      host = "docs";
      port = 30085;
      body = "100m";
      secrets = [ "SECRET_KEY" "ADMIN_PASSWORD" ];
      dirs =
      [
        (app "${st.state}/paperless")
        (subvol "${st.bulk}/documents")
        (app "${st.bulk}/documents/media")
        (app "${st.bulk}/documents/export")
        # drop files in here as ${username}
        (own "d" "2775" (toString uid) "users" "${st.bulk}/documents/consume")
      ];
      oidc = true;
      oidcVars = on: { apps = lib.optionalString on "allauth.socialaccount.providers.openid_connect"; };
    };
    jellyfin =
    {
      host = "media";
      port = 30096;
      body = "20m";
      dirs =
      [
        (app "${st.state}/jellyfin")
        (app "${st.cache}/jellyfin")
        (app "${st.scratch}/jellyfin-transcodes")
        # yours to fill; jellyfin only gets them read-only
        (subvol "${st.bulk}/music")
        (subvol "${st.bulk}/video")
      ];
      # it asks for the GPU, so the plugin comes with it or the pod stays Pending
      extra = [ "intel-gpu" ];
    };
    # upstream runs it as root, so its dirs are root's
    immich =
    {
      host = "photos";
      port = 30283;
      body = "100m";
      secrets = [ "DB_PASSWORD" ];
      dirs =
      [
        (own "v" "0700" "root" "root" "${st.bulk}/photos")
        (root "${st.cache}/immich-thumbs")
        (root "${st.cache}/immich-models")
        (root "${st.scratch}/immich-encoded-video")
        (root "${st.state}/immich")
        (root "${st.state}/immich/postgres")
      ];
      postgres =
      {
        deployment = "immich-postgres";
        user = "postgres";
      };
    };
  };

  enabled = lib.filterAttrs (n: _: lib.elem n cfg.apps) apps;
  proxied = lib.filterAttrs (_: a: a ? host) enabled;

  fqdn = a: "${a.host}.${config.proxy.domain}";
  sealedOidc = n: ./k8s/oidc + "/${n}.sealed.yaml";
  hasOidc = n: a: a.oidc or false && builtins.pathExists (sealedOidc n);

  # LAN clients go straight to nginx: the apex and every proxied app
  customDNS = lib.optionals (cfg.lanAddress != null)
    ([
      "customDNS:"
      "  mapping:"
      "    ${config.proxy.domain}: ${cfg.lanAddress}"
    ]
    ++ lib.mapAttrsToList (_: a: "    ${fqdn a}: ${cfg.lanAddress}") proxied);

  vars =
  {
    domain = config.proxy.domain;
    tz = config.time.timeZone;
    inherit uid username email alertTopic;
    render = config.ids.gids.render;
    gpu = cfg.gpuResource;
    # a YAML block, indented to fit blocky's ConfigMap
    "blocky.customDNS" = lib.concatMapStrings (l: "    ${l}\n") customDNS;
    inherit (st) state cache scratch bulk;
  }
  # every app's, so gatus and glance can list the others
  // lib.concatMapAttrs (n: a: lib.optionalAttrs (a ? host)
  {
    "${n}.host" = fqdn a;
    "${n}.port" = a.port;
  }
  // lib.optionalAttrs (a.oidc or false)
  {
    "${n}.oidc" = lib.boolToString (hasOidc n a);
  }
  // lib.mapAttrs' (k: v: lib.nameValuePair "${n}.${k}" v) ((a.oidcVars or (_: { })) (hasOidc n a))) apps;

  manifest = name: pkgs.writeText "${name}.yaml" (subst vars (builtins.readFile ./k8s/${name}.yaml));
  manifests = lib.unique (lib.concatLists (lib.mapAttrsToList (n: a: [ n ] ++ a.extra or [ ]) enabled));

  secretSpec = pkgs.writeText "k3s-app-secrets" (lib.concatStrings (lib.mapAttrsToList
    (n: a: lib.optionalString (a ? secrets) "${n} ${n} ${lib.concatStringsSep " " a.secrets}\n")
    enabled));

  dirRules = pkgs.writeText "k3s-app-dirs.conf" (lib.concatLines
    ([ (root st.state) ] ++ lib.concatLists (lib.mapAttrsToList (_: a: a.dirs or [ ]) enabled)));

  lanPorts = proto: lib.concatLists (lib.mapAttrsToList (_: a: a.lan.${proto} or [ ]) enabled);

  sealOidc = pkgs.writeShellApplication
  {
    name = "seal-oidc";
    runtimeInputs = [ config.services.k3s.package pkgs.kubeseal ];
    text = builtins.readFile ./k8s/seal-oidc.sh;
  };
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

    lanAddress = lib.mkOption
    {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "192.168.2.200";
      description = ''
        This host's LAN address. Blocky answers the domain and every app's subdomain with it
        (split-horizon), so LAN clients reach nginx directly; needs proxy.lanSubnets.
      '';
    };

    gpuResource = lib.mkOption
    {
      type = lib.types.str;
      default = "gpu.intel.com/i915";
      example = "gpu.intel.com/xe";
      description = "Device plugin resource Jellyfin asks for: i915 for Arc A-series, xe for B-series.";
    };

    # for other modules
    onFailure = lib.mkOption
    {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      default = lib.optional (cfg.enable && enabled ? ntfy) "ntfy-alert@%n.service";
      description = "OnFailure= units that push the failure to ntfy, empty without ntfy.";
    };

    postgres = lib.mkOption
    {
      type = lib.types.listOf lib.types.attrs;
      readOnly = true;
      default = lib.mapAttrsToList (n: a: a.postgres // { namespace = n; })
        (lib.filterAttrs (_: a: a ? postgres) enabled);
      description = "Postgres deployments of the enabled apps, for backups.";
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
      {
        assertion = cfg.lanAddress == null || config.proxy.lanSubnets != [ ];
        message = "k3s.lanAddress sends LAN clients to nginx directly: set proxy.lanSubnets so it lets them in";
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
      }) manifests)
      # phase 2, like the ddns token: sealed with `seal-oidc` once Pocket ID made the client
      // lib.mapAttrs' (n: _: lib.nameValuePair "app-${n}-oidc" { source = sealedOidc n; })
        (lib.filterAttrs hasOidc enabled);
    };

    proxy.hosts = lib.mapAttrs' (_: a: lib.nameValuePair a.host
    {
      inherit (a) port;
      maxBodySize = a.body or null;
    }) proxied;

    # hostPorts are DNATed past INPUT anyway; listed so the firewall says what's open
    networking.firewall.allowedTCPPorts = lanPorts "tcp";
    networking.firewall.allowedUDPPorts = lanPorts "udp";

    environment.systemPackages = lib.optional (lib.any (a: a.oidc or false) (lib.attrValues enabled)) sealOidc;

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
      path = [ config.services.k3s.package pkgs.openssl pkgs.coreutils pkgs.mkpasswd ];
      serviceConfig =
      {
        Type = "oneshot";
        RemainAfterExit = true;
        UMask = "0077";
        TimeoutStartSec = "6min";
        ExecStart = "${pkgs.bash}/bin/bash ${./k8s/secrets.sh} ${secretSpec}";
      };
    };

    # OnFailure=ntfy-alert@%n.service: the unit's last log lines to the alerts topic
    systemd.services."ntfy-alert@" = lib.mkIf (enabled ? ntfy)
    {
      description = "Push %i's failure to ntfy";
      path = [ config.services.k3s.package pkgs.coreutils pkgs.curl pkgs.inetutils config.systemd.package ];
      serviceConfig =
      {
        Type = "oneshot";
        UMask = "0077";
        ExecStart = "${pkgs.bash}/bin/bash ${./k8s/ntfy-alert.sh} %i ${toString apps.ntfy.port} ${alertTopic}";
      };
    };
  };
}
