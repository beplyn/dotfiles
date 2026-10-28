{
  imports = [ ./hardware.nix ];

  networking.hostName = "anvil";
  # Kept on every host for now; prune per host once the refactor lands.
  docker.enable = true;
  qbittorrent.enable = true;
  qbittorrent.openWebUI = false;
  gaming.enable = true;
  llm.enable = true;

  system.stateVersion = "26.11";
}
