# Intel Arc, wired NICs.
{ pkgs, ... }:

{
  # headless doesn't enable graphics; iHD + oneVPL for VA-API/QSV, compute-runtime for OpenCL
  hardware.enableRedistributableFirmware = true;
  hardware.graphics =
  {
    enable = true;
    extraPackages = with pkgs;
    [
      intel-media-driver
      vpl-gpu-rt
      intel-compute-runtime
    ];
  };
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  # intel_gpu_top
  hardware.intel-gpu-tools.enable = true;

  # wake-on-lan on every wired NIC (also enable it in the BIOS)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="en*", RUN+="${pkgs.ethtool}/bin/ethtool -s $name wol g"
  '';
  # stop NetworkManager resetting it on connect (64 = magic)
  networking.networkmanager.settings.connection."ethernet.wake-on-lan" = 64;
}
