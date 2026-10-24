# Ryzen 7 7800X3D + Radeon RX 7900 XTX, 32 GB RAM.
{
  # amdgpu needs the RDNA3 firmware blobs; microcode for Zen 4.
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  # Mesa ships RADV (Vulkan) and radeonsi VA-API/VDPAU, so no extra driver
  # packages are needed. enable32Bit adds the 32-bit stack for Steam/Proton.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Load amdgpu in the initrd: early KMS gives Plymouth the full-resolution
  # unlock screen instead of the firmware framebuffer.
  hardware.amdgpu.initrd.enable = true;

  # Compressed swap in RAM; with zram, a high swappiness is the recommended
  # setting because swapping to it is cheap.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };
  boot.kernel.sysctl."vm.swappiness" = 180;

  services.fwupd.enable = true;
}
