# Shared by NixOS and Home Manager. Stylix itself is configured once at the
# system level and propagates to Home Manager, so only NixOS loads stylix.nix;
# Home Manager's lib carries `lib.hm`, NixOS's does not.
{ lib, ... }:

{
  imports =
  [
    ./palette.nix
    ./shell.nix
  ]
  ++ lib.optional (!(lib ? hm)) ./stylix.nix;
}
