{
  config,
  lib,
  osConfig,
  ...
}:

# what look.lua and session.lua take from Nix: the shell theme, the
# scrolling layout's columns and the keyboard
let
  t = config.themes.shell;
  xkb = osConfig.services.xserver.xkb;
  c = config.lib.stylix.colors;
in
{
  wayland.windowManager.hyprland.extraLuaFiles = config.lib.haku.hyprlandData "theme"
  {
    inherit (t) gaps border radius;
    # focused windows: the accents in a gradient; the rest sit on base03
    border_colors = map (n: c.${n}) [ "base08" "base0A" "base0B" "base0C" "base0D" "base0E" ];
    inactive_border = c.base03;
    # half the screen by default; Mod+R cycles a third, a half and two thirds
    column_width = 0.5;
    column_widths = lib.concatMapStringsSep ", " (w: lib.substring 0 5 (toString w))
    [
      (1.0 / 3.0)
      (1.0 / 2.0)
      (2.0 / 3.0)
    ];
    kb_layout = xkb.layout;
    kb_variant = xkb.variant;
    # the host's (nixos/desktop/touchpad.nix)
    natural_scroll = osConfig.touchpad.naturalScroll;
    scroll_factor = osConfig.touchpad.scrollFactor;
  };
}
