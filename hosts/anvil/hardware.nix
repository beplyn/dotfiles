# Ryzen 7 7800X3D + Radeon RX 7900 XTX, 32 GB RAM.
{
  # RDNA3 firmware, Zen 4 microcode
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  # mesa covers RADV/VA-API; 32-bit for Steam
  hardware.graphics =
  {
    enable = true;
    enable32Bit = true;
  };

  # early KMS: full-res Plymouth unlock
  hardware.amdgpu.initrd.enable = true;

  # zram swap; high swappiness is fine since it's cheap
  zramSwap =
  {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };
  boot.kernel.sysctl."vm.swappiness" = 180;

  services.fwupd.enable = true;
}
