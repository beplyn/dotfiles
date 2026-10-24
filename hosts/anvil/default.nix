{
  imports = [ ./hardware.nix ];

  networking.hostName = "anvil";
  gaming.enable = true;
  qbittorrent.openWebUI = false;

  system.stateVersion = "26.11";
}
