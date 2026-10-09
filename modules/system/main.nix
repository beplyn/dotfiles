{ ... }:

{
  imports = [
    ./shell.nix
    ./pkgs.nix
    ./gaming.nix
  ];
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
