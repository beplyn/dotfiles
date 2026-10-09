{ config, lib, pkgs, ... }:

{
  gtk = {
    enable = true;
    theme = lib.mkIf (config.themes.active == "catppuccin") {
      name = "catppuccin-mocha-mauve-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "mauve" ];
        size = "standard";
        variant = "mocha";
      };
    };
  };
}
