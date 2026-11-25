{
  config,
  lib,
  pkgs,
  ...
}:

# on the host (needs the disks): Beszel for stats, Scrutiny for SMART. Behind tinyauth;
# state is regenerable, so not backed up
let
  cfg = config.monitoring;
  hub = config.services.beszel.hub;
  keyDir = "/run/beszel-key";
  scrutinyPort = 8072;
in
{
  options.monitoring =
  {
    enable = lib.mkEnableOption "Beszel and Scrutiny, proxied behind tinyauth";

    metricsHost = lib.mkOption
    {
      type = lib.types.str;
      default = "metrics";
      description = "Subdomain of proxy.domain for Beszel.";
    };

    disksHost = lib.mkOption
    {
      type = lib.types.str;
      default = "disks";
      description = "Subdomain of proxy.domain for Scrutiny.";
    };
  };

  config = lib.mkIf cfg.enable
  {
    assertions =
    [
      {
        assertion = config.proxy.enable && config.proxy.authRequest != null;
        message = "monitoring is reached through nginx behind tinyauth: enable proxy and the tinyauth app";
      }
    ];

    services.beszel.hub =
    {
      enable = true;
      environment =
      {
        APP_URL = "https://${cfg.metricsHost}.${config.proxy.domain}";
        # tinyauth login: the Beszel user with your Pocket ID email, no second password
        TRUSTED_AUTH_HEADER = "Remote-Email";
      };
    };

    # add it in the hub once: Add System, host 127.0.0.1, port 45876
    services.beszel.agent =
    {
      enable = true;
      smartmon.enable = true;
      environment =
      {
        KEY_FILE = "${keyDir}/key.pub";
        LISTEN = "127.0.0.1:45876";
      };
    };

    systemd.services.beszel-key =
    {
      description = "Hand the Beszel hub's public key to its agent";
      requires = [ "beszel-hub.service" ];
      after = [ "beszel-hub.service" ];
      path = [ pkgs.openssh pkgs.coreutils ];
      serviceConfig =
      {
        Type = "oneshot";
        RemainAfterExit = true;
        RuntimeDirectory = baseNameOf keyDir;
        RuntimeDirectoryMode = "0755";
        ExecStart = lib.escapeShellArgs
        [
          "${pkgs.bash}/bin/bash"
          ./beszel-key.sh
          "${hub.dataDir}/beszel_data/id_ed25519"
          "${keyDir}/key.pub"
        ];
      };
    };

    systemd.services.beszel-agent =
    {
      requires = [ "beszel-key.service" ];
      after = [ "beszel-key.service" ];
    };

    services.scrutiny =
    {
      enable = true;
      collector.enable = true;
      settings.web.listen =
      {
        host = "127.0.0.1";
        port = scrutinyPort;
      };
    };

    proxy.hosts =
    {
      ${cfg.metricsHost} =
      {
        inherit (hub) port;
        auth = true;
      };
      ${cfg.disksHost} =
      {
        port = scrutinyPort;
        auth = true;
      };
    };
  };
}
