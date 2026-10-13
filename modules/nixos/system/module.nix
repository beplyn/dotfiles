{ ... }:

{
  imports = [
    ./shell.nix
    ./fonts.nix
    ./tools.nix
    ./pkgs.nix
    ./gaming.nix
    ./starship.nix
  ];
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
