{
  config,
  lib,
  pkgs,
  subst,
  ...
}:

let
  # GRUB draws one mode: the primary monitor's, 1080p on hosts without monitors
  primary = lib.findFirst (m: m.primary) (lib.head (config.monitors ++ [ null ])) config.monitors;
  screen = if primary != null then { inherit (primary) width height; } else { width = 1920; height = 1080; };
in
{
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 3;

  boot.loader.grub =
  {
    enable = true;
    device = "nodev";
    efiSupport = true;
    # falls back when the firmware has no such mode
    gfxmodeEfi = lib.mkIf (primary != null) "${toString screen.width}x${toString screen.height},auto";
    # older generations: nixos-rebuild --rollback
    configurationLimit = 10;
    # other installed OSes (Windows, other distros), found at rebuild time
    useOSProber = true;
    # anything with an EFI loader, found at boot time (USB sticks too)
    extraEntries = builtins.readFile ./grub-removable.cfg;
    theme = import ./grub-theme.nix { inherit config lib pkgs subst screen; };
  };
}
