{
  lib,
  pkgs,
  ...
}:

{
  users.groups.media = { };

  services.qbittorrent = {
    enable = true;
    user = "qbittorrent";
    group = "media";
    openFirewall = false;
  };

  users.users.qbittorrent = {
    isSystemUser = true;
    home = "/var/lib/qbittorrent";
    createHome = true;
    group = "media";
  };

  systemd.services.qbittorrent = {
    environment.HOME = "/var/lib/qbittorrent";
    serviceConfig = {
      StateDirectory = "qbittorrent";
      ExecStart = lib.mkForce [
        ""
        "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=8090"
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 8090 ];
}
