{
  config,
  lib,
  pkgs,
  ...
}:

let
  port = 8090;
in
{
  options.qbittorrent =
  {
    enable = lib.mkEnableOption "qBittorrent (headless, web UI on port ${toString port})";

    openWebUI = lib.mkOption
    {
      type = lib.types.bool;
      default = true;
      description = "Open the qBittorrent web UI port (${toString port}) in the firewall.";
    };
  };

  config = lib.mkIf config.qbittorrent.enable
  {
    users.groups.media = { };

    services.qbittorrent =
    {
      enable = true;
      user = "qbittorrent";
      group = "media";
      openFirewall = false;
    };

    users.users.qbittorrent =
    {
      isSystemUser = true;
      home = "/var/lib/qbittorrent";
      createHome = true;
      group = "media";
    };

    systemd.services.qbittorrent =
    {
      environment.HOME = "/var/lib/qbittorrent";
      serviceConfig =
      {
        StateDirectory = "qbittorrent";
        ExecStart = lib.mkForce
        [
          ""
          "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=${toString port}"
        ];
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf config.qbittorrent.openWebUI [ port ];
  };
}
