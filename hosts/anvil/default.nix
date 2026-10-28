{
  imports = [ ./hardware.nix ];

  networking.hostName = "anvil";
  docker.enable = true;
  qbittorrent.enable = true;
  qbittorrent.openWebUI = false;
  gaming.enable = true;
  llm.enable = true;

  system.stateVersion = "26.11";
}
