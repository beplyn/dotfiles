{
  imports =
  [
    ./hardware.nix
  ];

  networking.hostName = "shulker";
  docker.enable = true;
  qbittorrent.enable = true;
  encryption.enable = false;
  services.openssh.enable = true;

  system.stateVersion = "26.11";
}
