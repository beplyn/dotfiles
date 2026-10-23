{ pkgs, config, ... }:

{
  security.polkit.enable = true;

  programs.niri.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.niri.default = [ "gnome" "gtk" ];
  };
}
