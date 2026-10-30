{ config, lib, pkgs, ... }:

let
  p = config.themes.palette;
in
{
  home.packages =
  [
    pkgs.btop
  ];

  xdg.configFile."btop/btop.conf".source = ./btop.conf;

  xdg.configFile."btop/themes/theme.theme".text = lib.replaceStrings
    (map (n: "@${n}@") (lib.attrNames p))
    (lib.attrValues p)
    (builtins.readFile ./btop.theme);
}
