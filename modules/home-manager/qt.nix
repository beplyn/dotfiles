{ config, lib, pkgs, ... }:

{
  home.packages = lib.optionals (config.themes.active == "catppuccin") [
    (pkgs.catppuccin-kvantum.override {
      accent = "mauve";
      variant = "mocha";
    })
    pkgs.catppuccin-qt5ct
    pkgs.qt6Packages.qtstyleplugin-kvantum
  ];

  home.sessionVariables = lib.mkIf (config.themes.active == "catppuccin") {
    QT_QPA_PLATFORMTHEME = "qt5ct";
    QT_STYLE_OVERRIDE = "kvantum";
  };

  xdg.configFile."Kvantum/kvantum.kvconfig" = lib.mkIf (config.themes.active == "catppuccin") {
    text = ''
      [General]
      theme=catppuccin-mocha-mauve
    '';
  };

  xdg.configFile."qt5ct/qt5ct.conf" = lib.mkIf (config.themes.active == "catppuccin") {
    text = ''
      [Appearance]
      color_scheme_path=${pkgs.catppuccin-qt5ct}/share/qt5ct/colors/catppuccin-mocha-mauve.conf
      style=kvantum
    '';
  };

  xdg.configFile."qt6ct/qt6ct.conf" = lib.mkIf (config.themes.active == "catppuccin") {
    text = ''
      [Appearance]
      color_scheme_path=${pkgs.catppuccin-qt5ct}/share/qt6ct/colors/catppuccin-mocha-mauve.conf
      style=kvantum
    '';
  };
}
