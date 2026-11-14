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
    ./starship
    ./greeting
    ./packages.nix
    ./toolbox.nix
    ./unfree.nix
    ./users.nix
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
