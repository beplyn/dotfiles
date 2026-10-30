{
  imports = [ ./hardware.nix ];

  networking.hostName = "anvil";
  docker.enable = true;
  qbittorrent.enable = true;
  qbittorrent.openWebUI = false;
  gaming.enable = true;
  llm.enable = true;

  # Connector names are guesses; confirm with `niri msg outputs` on anvil.
  monitors =
  [
    {
      name = "DP-1";
      width = 2560;
      height = 1440;
      refresh = 200.0;
      primary = true;
    }
    {
      name = "HDMI-A-1";
      width = 1920;
      height = 1080;
      refresh = 60.0;
    }
  ];

  system.stateVersion = "26.11";
}
