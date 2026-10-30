# PLACEHOLDER: replace with nixos-generate-config output before deploying
{
  fileSystems."/" =
  {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  warnings =
  [
    "beacon: hosts/beacon/hardware.nix is a placeholder; do not deploy until it is replaced with nixos-generate-config output."
  ];
}
