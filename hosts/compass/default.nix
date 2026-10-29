{
  imports = [ ./hardware.nix ];

  networking.hostName = "compass";
  docker.enable = false;
  qbittorrent.enable = false;
  encryption.device = "/dev/disk/by-uuid/b92ea2f5-494b-43e6-adcb-53b98d1b0847";

  system.stateVersion = "26.11";
}
