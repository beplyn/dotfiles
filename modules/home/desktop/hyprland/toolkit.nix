{ config, lib, ... }:

# hyprtoolkit's palette (hypr/hyprtoolkit.conf), shared by the apps built on
# it: hyprlauncher, hyprshutdown, hyprpwcenter and hyprland-dialog. Colours,
# radius and font from the theme, like the shell's
let
  p = config.themes.palette;
  s = config.themes.shell;
  rgb = color: "rgb(${lib.removePrefix "#" color})";
in
{
  xdg.configFile."hypr/hyprtoolkit.conf".text = lib.hm.generators.toHyprconf
  {
    attrs =
    {
      background = rgb p.background;
      base = rgb p.mantle;
      alternate_base = rgb p.surface;
      text = rgb p.foreground;
      bright_text = rgb p.brightest;
      link_text = rgb p.blue;
      accent = rgb p.accent;
      accent_secondary = rgb p.blue;

      rounding_large = s.radius;
      rounding_small = s.radius / 2;

      font_family = config.stylix.fonts.monospace.name;
      font_family_monospace = config.stylix.fonts.monospace.name;
      font_size = s.popupFontSize + 1;
      small_font_size = s.popupFontSize;
      icon_theme = config.stylix.icons.dark;
    };
  };

  # the daemon reads the palette when it starts
  systemd.user.services.hyprlauncher.Unit.X-Restart-Triggers =
  [
    "${config.xdg.configFile."hypr/hyprtoolkit.conf".source}"
  ];
}
