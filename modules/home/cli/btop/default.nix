{ config, pkgs, subst, ... }:

let
  p = config.themes.palette;
in
{
  home.packages =
  [
    pkgs.btop
  ];

  xdg.configFile."btop/btop.conf".source = ./btop.conf;

  xdg.configFile."btop/themes/theme.theme".text = subst p (builtins.readFile ./btop.theme);
}
