{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.encryption;

  # Plymouth wants a single font file; take the regular face of Stylix's
  # monospace font so the prompt follows whatever font Stylix is set to.
  plymouthFont = pkgs.runCommand "plymouth-font.ttf" { } ''
    font="$(find ${config.stylix.fonts.monospace.package} -name '*Regular.ttf' | sort | head -n1)"
    if [ -z "$font" ]; then
      font="$(find ${config.stylix.fonts.monospace.package} -name '*.ttf' | sort | head -n1)"
    fi
    cp "$font" "$out"
  '';
in
{
  options.encryption =
  {
    enable = lib.mkOption
    {
      type = lib.types.bool;
      default = true;
      description = "LUKS-encrypted root, unlocked from a Stylix-themed Plymouth prompt.";
    };

    device = lib.mkOption
    {
      type = lib.types.str;
      default = "/dev/disk/by-partlabel/cryptroot";
      description = "The LUKS container holding the root filesystem.";
    };
  };

  config = lib.mkIf cfg.enable
  {
    boot.initrd.systemd.enable = true;

    boot.initrd.luks.devices.cryptroot =
    {
      inherit (cfg) device;
      allowDiscards = true;
    };

    fileSystems."/" =
    {
      device = lib.mkDefault "/dev/mapper/cryptroot";
      fsType = lib.mkDefault "ext4";
    };

    boot.plymouth =
    {
      enable = true;
      font = "${plymouthFont}";
    };
    stylix.targets.plymouth.enable = true;

    # Keep kernel/systemd chatter off the splash so the prompt is all you see.
    boot.consoleLogLevel = 3;
    boot.initrd.verbose = false;
    boot.kernelParams =
    [
      "quiet"
      "splash"
      "udev.log_level=3"
      "rd.systemd.show_status=auto"
    ];
  };
}
