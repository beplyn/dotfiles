{ pkgs, ... }:

{
  home.packages = [
    pkgs.protonmail-desktop
  ];

  stylix.targets.gtk.enable = true;
}
