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
    # other installed OSes (Windows, other distros), found at rebuild time
    useOSProber = true;
    # anything with an EFI loader, found at boot time (USB sticks too)
    extraEntries = builtins.readFile ./grub-removable.cfg;
  };
}
