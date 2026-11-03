{
  config,
  lib,
  osConfig,
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
  toasts = ''appid:^steam$,title:^notificationtoasts_\d+_desktop$'';
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
      sloppyfocus=1

      # gaps, borders, corners, shadows
      gappih=${toString niri.layout.gaps}
      gappiv=${toString niri.layout.gaps}
      gappoh=${toString niri.layout.gaps}
      gappov=${toString niri.layout.gaps}
      borderpx=${toString niri.layout.border.width}
      focuscolor=${color p.accent "ff"}
      bordercolor=${color p.surface "ff"}
      urgentcolor=${color p.red "ff"}
      rootcolor=${color p.background "ff"}
      border_radius=${toString config.themes.shell.radius}
      shadows=1
      shadowscolor=${color p.background "80"}
      shadows_size=4
      shadows_blur=30
      shadows_position_y=4

      # scroller on every tag: niri's columns
      ${lib.concatMapStrings (i: "tagrule=id:${toString i},layout_name:scroller\n") (lib.range 1 9)}
      scroller_default_proportion=${toString niri.layout.default-column-width.proportion}
      scroller_default_proportion_single=${toString niri.layout.default-column-width.proportion}
      scroller_proportion_preset=${lib.concatStringsSep "," presets}
      scroller_focus_center=0
      scroller_prefer_center=0

      # rules
      windowrule=focused_opacity:0.75,unfocused_opacity:0.75,appid:^equibop$
      windowrule=focused_opacity:0.75,unfocused_opacity:0.75,appid:^steam$
      # Steam toasts top right, unfocused
      windowrule=isfloating:1,isopensilent:1,offsetx:100,offsety:-100,${toasts}
      windowrule=isfloating:1,appid:^com.gabm.satty$
    ''
  );
}
