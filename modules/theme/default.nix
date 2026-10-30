# Shared by NixOS and HM; stylix.nix is NixOS only.
{ lib, ... }:

{
  imports =
  [
    ./palette.nix
    ./shell.nix
  ]
  ++ lib.optional (!(lib ? hm)) ./stylix.nix;
}
