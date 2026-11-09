{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

# input, gaps, borders, layout and rules mirrored from niri
let
  p = config.themes.palette;
  niri = config.programs.niri.settings;
  xkb = osConfig.services.xserver.xkb;
  # "#rrggbb" -> 0xrrggbbaa
  color = c: alpha: "0x${lib.removePrefix "#" c}${alpha}";
  # niri's preset column widths, as scroller proportions
  presets = map (w: lib.substring 0 5 (toString w.proportion)) niri.layout.preset-column-widths;
  toasts = ''app_id:^steam$,title:^notificationtoasts_\d+_desktop$'';
  systemctl = lib.getExe' pkgs.systemd "systemctl";
  # sway leaves graphical-session.target up, so mango-session.target alone doesn't
  # restart quickshell and co. that died with it; cycle the session onto mango
  session = pkgs.writeShellScript "mango-session" ''
    ${systemctl} --user stop graphical-session.target
    ${systemctl} --user reset-failed
    ${systemctl} --user start mango-session.target
    # mango stops nothing on exit
    ${lib.getExe config.lib.haku.sessionWatch}
  '';
in
{
  xdg.configFile."mango/settings.conf".source = config.lib.haku.mangoConf "settings" (
    ''
      # input
      xkb_rules_layout=${xkb.layout}
    ''
    + lib.optionalString (xkb.variant != "") ''
      xkb_rules_variant=${xkb.variant}
    ''
    + ''
      sloppy_focus=1
      # the host's touchpad scrolling (nixos/desktop/touchpad.nix); mango's
      # factor scales every scroll axis, the mouse wheel's too
      trackpad_natural_scrolling=${if osConfig.touchpad.naturalScroll then "1" else "0"}
      axis_scroll_factor=${toString osConfig.touchpad.scrollFactor}

      # session
      exec_once=${session}

      # gaps, borders, corners, shadows
      gap_inner_horizontal=${toString niri.layout.gaps}
      gap_inner_vertical=${toString niri.layout.gaps}
      gap_outer_horizontal=${toString niri.layout.gaps}
      gap_outer_vertical=${toString niri.layout.gaps}
      border_px=${toString niri.layout.border.width}
      focus_color=${color p.accent "ff"}
      border_color=${color p.surface "ff"}
      urgent_color=${color p.red "ff"}
      root_color=${color p.background "ff"}
      border_radius=${toString config.themes.shell.radius}
      shadows=1
      shadows_color=${color p.background "80"}
      shadows_size=4
      shadows_blur=30
      shadows_position_y=4

      # scroller on every tag: niri's columns
      ${lib.concatMapStrings (i: "tag_rule=id:${toString i},layout_name:scroller\n") (lib.range 1 9)}
      scroller_default_proportion=${toString niri.layout.default-column-width.proportion}
      scroller_default_proportion_single=${toString niri.layout.default-column-width.proportion}
      scroller_proportion_preset=${lib.concatStringsSep "," presets}
      scroller_focus_center=0
      scroller_prefer_center=0
      # switch_layout (Mod+T) cycles columns, master/stack, splits, grid, deck, fullscreen
      circle_layout=scroller,tile,dwindle,grid,deck,monocle

      # rules
      window_rule=focused_opacity:0.75,unfocused_opacity:0.75,app_id:^equibop$
      window_rule=focused_opacity:0.75,unfocused_opacity:0.75,app_id:^steam$
      # Steam toasts top right, unfocused
      window_rule=is_floating:1,is_open_silent:1,offset_x:100,offset_y:-100,${toasts}
      window_rule=is_floating:1,app_id:^com.gabm.satty$
    ''
  );
}
