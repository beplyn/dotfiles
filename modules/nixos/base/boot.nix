# GRUB is themed by stylix.targets.grub (modules/theme/stylix.nix): palette
# background, sans-serif menu font and accent selection bar.
{
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  boot.loader.grub =
  {
    enable = true;
    device = "nodev";
    efiSupport = true;
    # Keep the menu short; older generations stay reachable through
    # `nixos-rebuild --rollback` until garbage collection.
    configurationLimit = 10;
  };
}
