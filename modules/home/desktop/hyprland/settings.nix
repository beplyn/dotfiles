{
  config,
  lib,
  osConfig,
  ...
}:

# what look.lua and session.lua take from Nix: niri's layout, the shell
# theme and the keyboard
let
  niri = config.programs.niri.settings;
  xkb = osConfig.services.xserver.xkb;
in
{
  wayland.windowManager.hyprland.extraLuaFiles = config.lib.haku.hyprlandData "theme"
  {
    inherit (niri.layout) gaps;
    border = niri.layout.border.width;
    inherit (config.themes.shell) radius;
    # niri's default and preset column widths, as scrolling ones
    column_width = niri.layout.default-column-width.proportion;
    column_widths = lib.concatMapStringsSep ", "
      (w: lib.substring 0 5 (toString w.proportion))
      niri.layout.preset-column-widths;
    kb_layout = xkb.layout;
    kb_variant = xkb.variant;
    # the host's (nixos/desktop/touchpad.nix), as in every session
    natural_scroll = osConfig.touchpad.naturalScroll;
    scroll_factor = osConfig.touchpad.scrollFactor;
  };
}
