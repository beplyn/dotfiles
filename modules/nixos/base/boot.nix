# GRUB theme: stylix.targets.grub
{
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  boot.loader.grub =
  {
    enable = true;
    device = "nodev";
    efiSupport = true;
    # older generations: nixos-rebuild --rollback
    configurationLimit = 10;
  };
}
