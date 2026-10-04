{ pkgs, ... }:

{
  home.packages = [
    (pkgs.catppuccin-kvantum.override {
      accent = "mauve";
      variant = "mocha";
    })
    pkgs.catppuccin-qt5ct
    pkgs.qt6Packages.qtstyleplugin-kvantum
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt5ct";
    QT_STYLE_OVERRIDE = "kvantum";
  };

  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=catppuccin-mocha-mauve
  '';

  xdg.configFile."qt5ct/qt5ct.conf".text = ''
    [Appearance]
    color_scheme_path=${pkgs.catppuccin-qt5ct}/share/qt5ct/colors/catppuccin-mocha-mauve.conf
    style=kvantum
  '';

  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    color_scheme_path=${pkgs.catppuccin-qt5ct}/share/qt6ct/colors/catppuccin-mocha-mauve.conf
    style=kvantum
  '';
}
