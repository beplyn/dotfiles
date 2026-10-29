{
  imports =
  [
    ./boot.nix
    ./encryption.nix
    ./locale.nix
    ./networking.nix
    ./ssh.nix
    ./shell.nix
    ./rebuild.nix
    ./starship.nix
    ./tools.nix
    ./packages.nix
  ];

  nixpkgs.config.allowUnfree = true;
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
