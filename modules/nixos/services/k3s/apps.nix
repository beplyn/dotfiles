{
  config,
  lib,
  pkgs,
  subst,
  username,
  email,
  ...
}:

# k3s apps, one manifest each in ./manifests; nginx reaches them on loopback NodePorts
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
  # yours, for the apps that run as you so their files on tank are yours too
  mine = own "d" "0700" username "users";
  # tank dirs both you and the app write, new files staying in the users group
  shared = own "d" "2775" (toString uid) "users";

  # host: subdomain (unset = not proxied)  port: NodePort
  # body: upload limit (Cloudflare: 100m)  timeout: upstream read timeout (Cloudflare: 100s)
  # secrets: generated keys (secrets.sh)   dirs: what the pods mount
  # extra: more manifests                  lan: host ports open to the LAN
  # postgres: what to pg_dumpall           oidc: Pocket ID login (manifests/oidc)
  # auth: tinyauth in front                authSkip(Token): paths left to the app's login
  # dnsOnly: unproxied subdomain (ddns)
  # apps with phone or CLI clients skip tinyauth and log in themselves
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
      lan.tcp = [ 22 ];
      oidc = true;
    };
    gatus =
    {
      host = "status";
      port = 30081;
      dirs = [ (app "${st.state}/gatus") ];
      auth = true;
    };
    glance =
    {
      host = "home";
      port = 30082;
      auth = true;
    };
    pocket-id =
    {
      host = "id";
      port = 30141;
      secrets = [ "ENCRYPTION_KEY" ];
      dirs = [ (app "${st.state}/pocket-id") ];
    };
    # forward auth in front of the auth apps, Pocket ID its only login
    tinyauth =
    {
      host = "auth";
      port = 30300;
      dirs =
      [
        (app "${st.state}/tinyauth")
        (app "${st.state}/tinyauth/oidc")
      ];
      oidc = true;
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
        (shared "${st.bulk}/documents/consume")
      ];
      oidc = true;
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
      oidc = true;
      dirs =
      [
        (own "v" "0700" "root" "root" "${st.bulk}/photos")
        (root "${st.cache}/immich-thumbs")
        (root "${st.cache}/immich-models")
        (root "${st.scratch}/immich-encoded-video")
        (root "${st.state}/immich")
        # postgres runs as 999 and owns this; root-owned locked it out
        (own "d" "0700" "999" "999" "${st.state}/immich/postgres")
      ];
      postgres =
      {
        deployment = "immich-postgres";
        user = "postgres";
      };
    };
    # plain .md files on tank, edited as ${username}
    silverbullet =
    {
      host = "notes";
      port = 30086;
      body = "100m";
      dirs = [ (subvol "${st.bulk}/notes") ];
      auth = true;
    };
    # its bootstrap and task runner want root and drop to the image's www-data (33)
    linkding =
    {
      host = "links";
      port = 30087;
      secrets = [ "ADMIN_PASSWORD" ];
      dirs = [ (own "d" "0750" "33" "33" "${st.state}/linkding") ];
      oidc = true;
    };
    # the phone apps log in themselves, so not behind tinyauth
    audiobookshelf =
    {
      host = "books";
      port = 30088;
      body = "100m";
      dirs =
      [
        (app "${st.state}/audiobookshelf")
        (app "${st.state}/audiobookshelf/config")
        (app "${st.state}/audiobookshelf/metadata")
        # yours to fill; it only gets it read-only, apart from the podcasts it downloads
        (subvol "${st.bulk}/books")
        (shared "${st.bulk}/books/podcasts")
      ];
    };
    # nothing kept, every file only lives as long as its request
    stirling-pdf =
    {
      host = "pdf";
      port = 30089;
      body = "100m";
      auth = true;
    };
    # all of tank, as ${username}; share links work without a login
    filebrowser =
    {
      host = "files";
      port = 30090;
      body = "100m";
      secrets = [ "ADMIN_PASSWORD" ];
      dirs = [ (mine "${st.state}/filebrowser") ];
      auth = true;
      authSkip =
      [
        "^~ /share/"
        "^~ /api/public/"
        "^~ /static/"
      ];
    };
    actual =
    {
      host = "budget";
      port = 30506;
      body = "20m";
      dirs = [ (app "${st.state}/actual") ];
      oidc = true;
    };
    # public: anyone can make and read pastes, no tinyauth
    wastebin =
    {
      host = "bin";
      port = 30091;
      body = "10m";
      secrets = [ "SIGNING_KEY" "PASSWORD_SALT" ];
      dirs = [ (app "${st.state}/wastebin") ];
    };
    searxng =
    {
      host = "search";
      port = 30092;
      secrets = [ "SECRET_KEY" ];
      auth = true;
    };
    # the phone apps log in themselves
    vikunja =
    {
      host = "tasks";
      port = 30093;
      body = "20m";
      secrets = [ "JWT_SECRET" "ADMIN_PASSWORD" ];
      dirs =
      [
        (app "${st.state}/vikunja")
        (app "${st.state}/vikunja/files")
      ];
      oidc = true;
    };
    # ownCloud Infinite Scale (Google Drive replacement); native OIDC, so no tinyauth
    ocis =
    {
      host = "drive";
      port = 30106;
      body = "100m";
      secrets = [ "OCIS_JWT_SECRET" "OCIS_TRANSFER_SECRET" "OCIS_MACHINE_AUTH_API_KEY" "OCIS_SERVICE_ACCOUNT_SECRET" "OCIS_SYSTEM_USER_API_KEY" ];
      dirs = [ (app "${st.state}/ocis") ];
      oidc = true;
    };
    # CalDAV/CardDAV clients log in with basic auth
    radicale =
    {
      host = "cal";
      port = 30094;
      secrets = [ "ADMIN_PASSWORD" "ADMIN_HASH=bcrypt:ADMIN_PASSWORD" ];
      dirs = [ (app "${st.state}/radicale") ];
    };
    # Subsonic clients log in themselves
    navidrome =
    {
      host = "music";
      port = 30095;
      secrets = [ "ADMIN_PASSWORD" ];
      dirs =
      [
        (app "${st.state}/navidrome")
        # jellyfin's too; it only gets it read-only
        (subvol "${st.bulk}/music")
      ];
      auth = true;
      # subsonic apps log in with navidrome's own password
      authSkip = [ "^~ /rest/" ];
    };
    # webhooks and forms are called by other services, without a login
    n8n =
    {
      host = "flow";
      port = 30097;
      body = "20m";
      secrets = [ "ENCRYPTION_KEY" ];
      dirs = [ (app "${st.state}/n8n") ];
    };
    # the atuin client syncs with its own account
    atuin =
    {
      host = "sh";
      port = 30098;
      body = "20m";
      dirs = [ (app "${st.state}/atuin") ];
    };
    changedetection =
    {
      host = "watch";
      port = 30099;
      dirs = [ (app "${st.state}/changedetection") ];
      auth = true;
    };
    mealie =
    {
      host = "recipes";
      port = 30100;
      body = "20m";
      dirs = [ (app "${st.state}/mealie") ];
      auth = true;
      oidc = true;
    };
    # paste a link: audio lands in navidrome's music, video in jellyfin's
    metube =
    {
      host = "dl";
      port = 30102;
      dirs =
      [
        (mine "${st.state}/metube")
        (subvol "${st.bulk}/music")
        (subvol "${st.bulk}/video")
      ];
      auth = true;
    };
    # .torrent or magnet: done lands in jellyfin's video, partial on scratch
    qbittorrent =
    {
      host = "torrent";
      port = 30103;
      body = "20m";
      dirs =
      [
        (mine "${st.state}/qbittorrent")
        (mine "${st.scratch}/qbittorrent")
        (subvol "${st.bulk}/video")
        # general torrent dir, also browsable in filebrowser
        (subvol "${st.bulk}/torrents")
      ];
      lan =
      {
        tcp = [ 6881 ];
        udp = [ 6881 ];
      };
      auth = true;
    };
    # go.<domain>/slug redirects, no login; the admin page is behind CHHOTO_PASSWORD
    chhoto =
    {
      host = "go";
      port = 30105;
      secrets = [ "ADMIN_PASSWORD" ];
      dirs = [ (app "${st.state}/chhoto") ];
    };
    # nothing kept: drawings stay in the browser unless exported
    excalidraw =
    {
      host = "draw";
      port = 30101;
      auth = true;
    };
    # vanilla on 25565; mc. is DNS-only (Cloudflare proxies only HTTP); Java scaled to 0
    minecraft =
    {
      host = "mc";
      port = 30110;
      body = "100m";
      secrets = [ "DB_ROOT_PASSWORD" "DB_PASSWORD" ];
      dirs =
      [
        (app "${st.state}/minecraft")
        # www-data in the panel image
        (own "d" "0750" "82" "82" "${st.state}/minecraft/pelican")
        # mariadb runs as 999
        (own "d" "0700" "999" "999" "${st.state}/minecraft/pelican-db")
      ];
      extra = [ "pelican" ];
      oidc = true;
      lan.tcp = [ 25565 ];
      dnsOnly = [ "mc" "*.mc" ];
    };
    # idles games for card drops; no web UI outside the cluster; asf-bot holds the login
    asf =
    {
      dirs = [ (app "${st.state}/asf") ];
    };
  };

  enabled = lib.filterAttrs (n: _: lib.elem n cfg.apps) apps;
  proxied = lib.filterAttrs (_: a: a ? host) enabled;

  fqdn = a: "${a.host}.${config.proxy.domain}";
  sealedOidc = n: ./manifests/oidc + "/${n}.sealed.yaml";
  hasOidc = n: a: a.oidc or false && builtins.pathExists (sealedOidc n);

  # LAN clients go straight to nginx: the apex and every proxied host, apps or not
  splitHorizonHosts =
    [ config.proxy.domain ]
    ++ map (h: "${h}.${config.proxy.domain}")
      (lib.unique (lib.filter (h: h != "@") (lib.attrNames config.proxy.hosts)
        ++ lib.filter (h: !lib.hasPrefix "*" h) cfg.dnsOnly));

  customDNS = lib.optionals (cfg.lanAddress != null)
    ([
      "customDNS:"
      "  mapping:"
      "    ${config.proxy.domain}: ${cfg.lanAddress}"
    ]
    # subdomains resolve on their own: "mc" covers every <label>.mc; "*" isn't a valid key
    ++ map (h: "    ${h}.${config.proxy.domain}: ${cfg.lanAddress}")
      (lib.unique (lib.filter (h: h != "@") (lib.attrNames config.proxy.hosts)
        ++ lib.filter (h: !lib.hasPrefix "*" h) cfg.dnsOnly)));

  # tinyauth ACLs per forward-auth app: members of wheel or the app's own group
  tinyauthAcl = lib.concatMapStrings (n:
    # tinyauth reads "_" as nesting, so the key segment has no separators
    let env = lib.toUpper (lib.replaceStrings [ "-" ] [ "" ] n);
    in
    "            - name: TINYAUTH_APPS_${env}_CONFIG_DOMAIN\n"
    + "              value: \"${fqdn enabled.${n}}\"\n"
    + "            - name: TINYAUTH_APPS_${env}_OAUTH_GROUPS\n"
    + "              value: \"wheel,${n}\"\n")
    (lib.attrNames (lib.filterAttrs (_: a: a.auth or false && a ? host) enabled));

  vars =
  {
    domain = config.proxy.domain;
    "tinyauth.acl" = tinyauthAcl;
    tz = config.time.timeZone;
    inherit uid username email alertTopic;
    useruid = config.users.users.${username}.uid;
    usergid = config.ids.gids.users;
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
  }) apps;

  manifest = name: pkgs.writeText "${name}.yaml" (subst vars (builtins.readFile ./manifests/${name}.yaml));
  manifests = lib.unique (lib.concatLists (lib.mapAttrsToList (n: a: [ n ] ++ a.extra or [ ]) enabled));

  secretSpec = pkgs.writeText "k3s-app-secrets" (lib.concatStrings (lib.mapAttrsToList
    (n: a: lib.optionalString (a ? secrets) "${n} ${n} ${lib.concatStringsSep " " a.secrets}\n")
    enabled));

  # unique: apps may share a dir (jellyfin's and navidrome's music)
  dirRules = pkgs.writeText "k3s-app-dirs.conf" (lib.concatLines (lib.unique
    ([ (root st.state) ] ++ lib.concatLists (lib.mapAttrsToList (_: a: a.dirs or [ ]) enabled))));

  lanPorts = proto: lib.concatLists (lib.mapAttrsToList (_: a: a.lan.${proto} or [ ]) enabled);

  sealOidc = pkgs.writeShellApplication
  {
    name = "seal-oidc";
    runtimeInputs = [ config.services.k3s.package pkgs.kubeseal ];
    text = builtins.readFile ./seal-oidc.sh;
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
      example = "192.168.1.10";
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

    dnsOnly = lib.mkOption
    {
      type = lib.types.listOf lib.types.str;
      readOnly = true;
      default = lib.concatMap (a: a.dnsOnly) (lib.attrValues (lib.filterAttrs (_: a: a ? dnsOnly) enabled));
      description = "Subdomains of the enabled apps that ddns points here without Cloudflare's proxy.";
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
      {
        assertion = !(enabled ? tinyauth) || enabled ? pocket-id;
        message = "tinyauth logs in through Pocket ID: add pocket-id to k3s.apps";
      }
    ];

    # what the NixOS default gives the first user, pinned: pods run as it
    users.users.${username}.uid = lib.mkDefault 1000;

    services.k3s =
    {
      # nginx proxies to them; nothing on the LAN gets around it
      extraFlags = [ "--kube-proxy-arg=nodeport-addresses=127.0.0.0/8" ];
      manifests = lib.listToAttrs (map (name:
      {
        name = "app-${name}";
        value.source = manifest name;
      }) manifests)
      # phase 2, like the ddns token: sealed with seal-oidc once Pocket ID has the client
      // lib.mapAttrs' (n: _: lib.nameValuePair "app-${n}-oidc" { source = sealedOidc n; })
        (lib.filterAttrs hasOidc enabled)
      # split-horizon in the cluster: pods resolve proxied hosts to lanAddress (no hairpin)
      # (own .server block, so CoreDNS does not duplicate NodeHosts)
      // lib.optionalAttrs (cfg.lanAddress != null)
      {
        coredns-custom.content =
        {
          apiVersion = "v1";
          kind = "ConfigMap";
          metadata =
          {
            name = "coredns-custom";
            namespace = "kube-system";
          };
          data."${config.proxy.domain}.server" = ''
            ${config.proxy.domain}:53 {
              errors
              cache 30
              hosts {
            ${lib.concatMapStrings (h: "    ${cfg.lanAddress} ${h}\n") splitHorizonHosts}    fallthrough
              }
              forward . /etc/resolv.conf
            }
          '';
        };
      };
    };

    proxy.hosts = lib.mapAttrs' (_: a: lib.nameValuePair a.host
    {
      inherit (a) port;
      maxBodySize = a.body or null;
      readTimeout = a.timeout or null;
      auth = a.auth or false;
      authSkip = a.authSkip or [ ];
      authSkipToken = a.authSkipToken or false;
    }) proxied;

    proxy.authRequest = lib.mkIf (enabled ? tinyauth) "http://127.0.0.1:${toString apps.tinyauth.port}/api/auth/nginx";

    # hostPorts bypass INPUT anyway; listed so the firewall shows what is open
    networking.firewall.allowedTCPPorts = lanPorts "tcp";
    networking.firewall.allowedUDPPorts = lanPorts "udp";

    environment.systemPackages = lib.optional (lib.any (a: a.oidc or false) (lib.attrValues enabled)) sealOidc;

    # only once every disk is mounted: pods fail rather than fill the system SSD
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
        ExecStart = "${pkgs.bash}/bin/bash ${./secrets.sh} ${secretSpec}";
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
        ExecStart = "${pkgs.bash}/bin/bash ${./ntfy-alert.sh} %i ${toString apps.ntfy.port} ${alertTopic}";
      };
    };
  };
}
