{ config, lib, pkgs, ... }:

# Wings on beacon, mc-router on :25565, and the sync that ties them to Panel in k3s
let
  cfg = config.pelican;
  inherit (config.proxy) domain;

  wingsVersion = "1.0.0-rc.3";
  wings = pkgs.runCommand "wings-${wingsVersion}"
  {
    src = pkgs.fetchurl
    {
      url = "https://github.com/pelican/wings/releases/download/v${wingsVersion}/wings_linux_amd64";
      hash = "sha256-NtYtQdYRLpzIVeD3X9bNB8PlQTY8Xdt030jCl6Gvi/Q=";
    };
  } ''install -Dm755 "$src" "$out/bin/wings"'';

  # the router's API is loopback only; the sync reaches it there
  routerImage = "docker.io/itzg/mc-router:1.56.5@sha256:e2f002006d617b2df898c9beec963baa212c685aae1df83de5a13ebf5b5966c9";
  routerApi = "127.0.0.1:25560";

  # wakers listen at allocation port + offset, so a stopped server's route lands there
  wakerOffset = 100;

  sync = pkgs.writers.writePython3Bin "pelican-mc-sync" { flakeIgnore = [ "E501" ]; }
    (builtins.readFile ./pelican-mc-sync.py);
in
{
  options.pelican.enable = lib.mkEnableOption "Pelican Wings, mc-router and the Minecraft sync on beacon";

  config = lib.mkIf cfg.enable
  {
    # game containers' own range, clear of k3s 10.42 and 10.43
    virtualisation.docker.daemon.settings.default-address-pools =
    [
      { base = "172.30.0.0/16"; size = 24; }
    ];

    # wings runs useradd for this user if it's missing; declared here, it exists
    users.groups.pelican = { };
    users.users.pelican =
    {
      isSystemUser = true;
      group = "pelican";
      home = "/var/lib/pelican";
      description = "Pelican Wings";
    };

    systemd.tmpfiles.rules =
    [
      "d /var/lib/pelican 0750 root root -"
      "d /etc/pelican 0750 root root -"
    ];

    # Wings reads the config Panel generates for this node; without it, it stays down
    systemd.services.pelican-wings =
    {
      description = "Pelican Wings game node";
      after = [ "docker.service" "network-online.target" ];
      wants = [ "network-online.target" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = "/etc/pelican/config.yml";
      serviceConfig =
      {
        ExecStart = "${wings}/bin/wings --config /etc/pelican/config.yml";
        WorkingDirectory = "/var/lib/pelican";
        Restart = "on-failure";
        RestartSec = "10s";
        # root for the docker socket; everything else locked down
        ProtectSystem = "strict";
        # wings writes its machine-id into its config dir at start
        ReadWritePaths = [ "/var/lib/pelican" "/var/log/pelican" "/etc/pelican" "/tmp" ];
        ProtectHome = true;
        # wings writes install scripts to /tmp/pelican and docker bind-mounts them;
        # the daemon runs outside this unit, so it needs the real /tmp
        PrivateTmp = false;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
        LogsDirectory = "pelican";
      };
    };

    # every server's Minecraft port, through mc-router on the host network
    systemd.services.mc-router =
    {
      description = "Minecraft subdomain router on :25565";
      after = [ "docker.service" "network-online.target" ];
      wants = [ "network-online.target" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig =
      {
        ExecStartPre = "-${pkgs.docker}/bin/docker rm -f mc-router";
        ExecStart = lib.concatStringsSep " "
        [
          "${pkgs.docker}/bin/docker run --rm --name mc-router --network host"
          routerImage
          "-port 25565"
          "-api-binding ${routerApi}"
        ];
        ExecStop = "${pkgs.docker}/bin/docker stop mc-router";
        Restart = "always";
        RestartSec = "5s";
      };
    };

    # routes, wake-on-join and idle stop; needs the Panel API token in /var/lib/pelican
    systemd.services.pelican-mc-sync =
    {
      description = "Sync Pelican servers into mc-router, wake on join, stop when idle";
      after = [ "mc-router.service" "pelican-wings.service" ];
      wants = [ "mc-router.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = "/var/lib/pelican/api-token";
      environment =
      {
        PANEL_URL = "https://mc.${domain}";
        ROUTER_URL = "http://${routerApi}";
        ROUTE_SUFFIX = "mc.${domain}";
        WAKER_OFFSET = toString wakerOffset;
        GAME_HOST = "172.18.0.1";
        IDLE_SECONDS = "900";
      };
      serviceConfig =
      {
        ExecStart = "${sync}/bin/pelican-mc-sync";
        Restart = "always";
        RestartSec = "10s";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        DynamicUser = true;
        # read as %d/api-token, root's 0750 dir stays closed to it
        LoadCredential = "api-token:/var/lib/pelican/api-token";
      };
    };

    # Wings' API sits behind nginx (TLS, websockets); Minecraft is raw TCP on :25565
    proxy.hosts.wings =
    {
      port = 8080;
      auth = false;
      websockets = true;
      maxBodySize = "100m";
    };

    networking.firewall =
    {
      # 2022: Wings' SFTP for server files
      allowedTCPPorts = [ 25565 2022 ];
      allowedUDPPorts = [ 25565 ];
    };
  };
}
