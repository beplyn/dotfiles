{
  imports = [ ./hardware.nix ./hardware-extra.nix ];

  networking.hostName = "anvil";
  encryption.device = "/dev/disk/by-uuid/52043e38-4ee0-4e79-9f48-53379ba2b743";
  docker.enable = true;
  qbittorrent.enable = true;
  qbittorrent.openWebUI = false;
  gaming.enable = true;
  llm.enable = true;
  toolbox.enable = true;
  rgb.enable = true;

  # the 7900 XTX; 13:00.0 is the 7800X3D's iGPU
  displayGpu = "0000:03:00.0";

  # connector names unverified (niri msg outputs); 1080p sits left
  monitors =
  [
    {
      name = "HDMI-A-1";
      width = 1920;
      height = 1080;
      refresh = 60.0;
    }
    {
      name = "DP-1";
      width = 2560;
      height = 1440;
      refresh = 200.0;
      primary = true;
    }
  ];

  system.stateVersion = "26.11";
}
