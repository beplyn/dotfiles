# Tiger Lake laptop, Iris Xe.
{ pkgs, ... }:

{
  # early KMS: native-res Plymouth unlock
  boot.initrd.kernelModules = [ "i915" ];

  # mesa covers iris/ANV; iHD + oneVPL for VA-API/QSV
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
}
