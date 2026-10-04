{ pkgs, config, ... }:

{
  imports = [
    ./boot.nix
    ./networking.nix
    ./locale.nix
    ./users.nix
    ./sddm.nix
    ./niri.nix
  ];
}
