{ pkgs, ... }:

{
  imports = [ ./hardware.nix ];

  networking.hostName = "compass";
  laptop.enable = true;
  # early KMS: native-res Plymouth unlock (here, hardware.nix gets regenerated)
  boot.initrd.kernelModules = [ "i915" ];

  # Iris Xe (Tiger Lake): mesa covers iris/ANV; iHD + oneVPL for VA-API/QSV
  hardware.enableRedistributableFirmware = true;
  hardware.graphics =
  {
    enable = true;
    extraPackages = with pkgs;
    [
      intel-media-driver
      vpl-gpu-rt
    ];
  };
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  hardware.intel-gpu-tools.enable = true;
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
