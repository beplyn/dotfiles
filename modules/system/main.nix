{ config, pkgs, ... }:

{
  imports = [
    ./shell.nix
    ./pkgs.nix
  ];
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
