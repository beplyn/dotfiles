{
  networking.hostName = "compass";
  # Kept on every host for now; prune per host once the refactor lands.
  docker.enable = true;
  qbittorrent.enable = true;

  system.stateVersion = "26.11";
}
