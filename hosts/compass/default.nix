{
  imports = [ ./hardware.nix ];

  networking.hostName = "compass";
  laptop = true;
  docker.enable = false;
  qbittorrent.enable = false;
  services.xserver.xkb.layout = "us";
  console.keyMap = "us";
  monitors =
  [
    {
      name = "eDP-1";
      width = 1920;
      height = 1080;
      refresh = 60.0;
      primary = true;
    }
  ];
  encryption.device = "/dev/disk/by-uuid/b92ea2f5-494b-43e6-adcb-53b98d1b0847";

  system.stateVersion = "26.11";
}
