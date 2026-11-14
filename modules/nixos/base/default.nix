{
  imports =
  [
    ./boot
    ./encryption
    ./locale.nix
    ./monitors.nix
    ./networking.nix
    ./ssh.nix
    ./shell
    ./rebuild
    ./starship.nix
    ./greeting
    ./packages.nix
    ./toolbox.nix
    ./unfree.nix
    ./forgejo.nix
  ];

  nix.settings.experimental-features =
  [
    "nix-command"
    "flakes"
  ];

  nix.optimise.automatic = true;
  nix.gc =
  {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
