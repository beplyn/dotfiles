{
  imports = [
    ./hardware.nix
  ];

  networking.hostName = "shulker";
  # Kept on every host for now; prune per host once the refactor lands.
  docker.enable = true;
  qbittorrent.enable = true;
  encryption.enable = false;
  services.openssh.enable = true;

  system.stateVersion = "26.11";
}
