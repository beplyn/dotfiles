{ lib, headless, ... }:

{
  imports = [
    ./shell.nix
    ./tools.nix
    ./pkgs.nix
    ./starship.nix
    ./llm.nix
  ]
  ++ lib.optionals (!headless) [
    ./fonts.nix
    ./gaming.nix
    ./niri.nix
  ];
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
