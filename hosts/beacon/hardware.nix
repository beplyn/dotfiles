# PLACEHOLDER so the flake evaluates. Replace with the output of
# `nixos-generate-config --show-hardware-config` from beacon itself before
# deploying: this root filesystem is a guess and will not boot as-is.
{
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  warnings = [
    "beacon: hosts/beacon/hardware.nix is a placeholder; do not deploy until it is replaced with nixos-generate-config output."
  ];
}
