{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

# niri's binds (niri/binds.nix) on the same keys, with the scroller layout
# standing in for niri's columns and tags for its workspaces; where mango
# has no equivalent the closest action is noted
let
  wezterm = lib.getExe config.programs.wezterm.package;
  walker = lib.getExe config.services.walker.package;
  mmsg = lib.getExe' osConfig.programs.mango.package "mmsg";
  # qs ipc call as a command string
  ipc = target: fn: args: lib.escapeShellArgs (config.lib.haku.ipc target fn ++ args);
  # through hypridle, whose lock_cmd skips an already running hyprlock
  loginctl = lib.getExe' pkgs.systemd "loginctl";
  wpctl = lib.getExe' pkgs.wireplumber "wpctl";
  brightnessctl = lib.getExe pkgs.brightnessctl;

  # a bind: modifiers, key, dispatcher and its arguments
  bind = mods: key: command: { inherit mods key command; };
  Mod = bind "SUPER";
  ModShift = bind "SUPER+SHIFT";
  ModCtrl = bind "SUPER+CTRL";
  ModAlt = bind "SUPER+ALT";
  None = bind "NONE";
  Shift = bind "SHIFT";
  spawn = cmd: "spawn,${cmd}";

  # niri asks before quitting too
  quit = "spawn_shell,[ \"$(printf 'Quit\\nCancel\\n' | ${walker} -d -p 'Quit mango?')\" = Quit ] && ${mmsg} dispatch quit";

  # titled binds, by section, for the hotkey overlay (Mod+/); the rest
  # (navigation, media keys) is untitled, as in niri's
  show = title: b: b // { inherit title; };
  sections =
  [
    {
      name = "Apps and shell";
      binds =
      [
        (show "Terminal" (Mod "Return" (spawn wezterm)))
        (show "Launcher" (Mod "space" (spawn walker)))
        (show "Clipboard history" (Mod "v" (spawn "${walker} -m clipboard")))
        (show "Control center" (Mod "a" (spawn (ipc "panels" "toggle" [ "control" ]))))
        (show "Dashboard" (Mod "d" (spawn (ipc "panels" "toggle" [ "dashboard" ]))))
        (show "Notification center" (Mod "n" (spawn (ipc "notifications" "toggle" [ ]))))
        (show "Toggle do not disturb" (ModShift "n" (spawn (ipc "notifications" "toggleDnd" [ ]))))
        (show "Screen recorder" (ModShift "r" (spawn (ipc "recorder" "toggle" [ ]))))
        (show "Wallpaper picker" (Mod "w" (spawn (lib.getExe pkgs.waypaper))))
        (show "Screenshot area" (None "Print" (spawn "screenshot area")))
        (show "Screenshot screen" (Shift "Print" (spawn "screenshot output")))
      ];
    }
    {
      name = "Session";
      binds =
      [
        (show "Close window" (Mod "q" "killclient"))
        (show "Quit mango" (ModShift "e" quit))
        (show "Lock screen" (ModAlt "l" (spawn "${loginctl} lock-session")))
        (show "Power menu" (Mod "x" (spawn (ipc "panels" "toggle" [ "power" ]))))
        (show "Show hotkeys" (Mod "slash" (spawn (ipc "panels" "toggle" [ "hotkeys" ]))))
        (show "Overview" (Mod "Tab" "toggleoverview"))
      ];
    }
    {
      name = "Window sizing";
      binds =
      [
        # maximize-column: the window fills the screen, keeping gaps and bar
        (show "Maximize window" (Mod "f" "togglemaximizescreen"))
        (show "Fullscreen window" (ModShift "f" "togglefullscreen"))
        (show "Toggle floating" (ModAlt "x" "togglefloating"))
        (show "Cycle column width" (Mod "r" "switch_proportion_preset"))
        # set-column-width ±10%: pixels here
        (show "Shrink column" (Mod "minus" "resizewin,-100,+0"))
        (show "Grow column" (Mod "equal" "resizewin,+100,+0"))
        (show "Consume / expel window left" (Mod "bracketleft" "scroller_stack,left"))
        (show "Consume / expel window right" (Mod "bracketright" "scroller_stack,right"))
      ];
    }
    {
      # what niri has no bind for
      name = "Mango only";
      binds =
      [
        (show "Toggle scrolling / tiling" (Mod "t" "switch_layout"))
        (show "Jump to window" (ModShift "Tab" "togglejump"))
        (show "Show scratchpad" (Mod "grave" "toggle_scratchpad"))
        (show "Send to scratchpad" (ModShift "grave" "minimized"))
        # tag 0: a tiled layer over the current tag
        (show "Toggle special tag" (Mod "o" "toggle_special_tag"))
        (show "Move to special tag" (ModShift "o" "tag_special_tag"))
        (show "Pin to all tags" (Mod "p" "toggleglobal"))
        (show "Keep above others" (ModShift "p" "toggleoverlay"))
        # tabbed groups
        (show "Group with window left" (Mod "g" "groupjoin,left"))
        (show "Leave group" (ModShift "g" "groupleave"))
        (show "Previous in group" (Mod "comma" "groupfocus,prev"))
        (show "Next in group" (Mod "period" "groupfocus,next"))
      ];
    }
  ];
  titled = lib.concatMap (s: s.binds) sections;

  untitled =
  [
    # same as Print, so untitled
    (ModShift "s" (spawn "screenshot area"))
    # other variants of Mod+Minus / Mod+Equal
    (ModShift "equal" "resizewin,+100,+0")
    (Mod "KP_Subtract" "resizewin,-100,+0")
    (Mod "KP_Add" "resizewin,+100,+0")

    # --- navigation -------------------------------------------------------
    (Mod "h" "focusdir,left")
    (Mod "l" "focusdir,right")
    (Mod "k" "focus_window_or_workspace,up")
    (Mod "j" "focus_window_or_workspace,down")

    (Mod "u" "viewtoright,0")
    (Mod "i" "viewtoleft,0")

    (ModShift "h" "exchange_client,left")
    (ModShift "l" "exchange_client,right")
    (ModShift "k" "exchange_client,up")
    (ModShift "j" "exchange_client,down")

    # tags can't be reordered; send the window to the next monitor
    (ModShift "u" "tagmon,right")
    (ModShift "i" "tagmon,left")

    (ModCtrl "h" "focusmon,left")
    (ModCtrl "l" "focusmon,right")

    # tagtoright follows the window, like move-column-to-workspace
    (ModCtrl "u" "tagtoright,0")
    (ModCtrl "i" "tagtoleft,0")
  ]
  # Mod(+Shift)+1..9: view / move to tag
  ++ lib.concatMap
    (i:
    let
      n = toString i;
    in
    [
      (Mod n "view,${n},0")
      (ModShift n "tag,${n},0")
    ])
    (lib.range 1 9);

  # work while locked
  media =
  [
    (None "XF86AudioRaiseVolume" (spawn "${wpctl} set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"))
    (None "XF86AudioLowerVolume" (spawn "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
    (None "XF86AudioMute" (spawn "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle"))
    (None "XF86AudioMicMute" (spawn "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
    (None "XF86MonBrightnessUp" (spawn "${brightnessctl} set 5%+"))
    (None "XF86MonBrightnessDown" (spawn "${brightnessctl} set 5%-"))
  ];

  line = kind: b: "${kind}=${b.mods},${b.key},${b.command}";

  # SUPER+SHIFT, slash -> Super+Shift+slash, as the overlay reads keys
  modName =
  {
    SUPER = "Super";
    SHIFT = "Shift";
    CTRL = "Ctrl";
    ALT = "Alt";
  };
  overlayKey = b:
    lib.concatStringsSep "+" (
      map (m: modName.${m}) (lib.filter (m: m != "NONE") (lib.splitString "+" b.mods)) ++ [ b.key ]
    );
in
{
  # read by the quickshell hotkey overlay
  lib.haku.mangoHotkeys = map
    (s:
    {
      inherit (s) name;
      binds = map
        (b:
        {
          key = overlayKey b;
          inherit (b) title;
        })
        s.binds;
    })
    sections;

  xdg.configFile."mango/binds.conf".source = config.lib.haku.mangoConf "binds" (
    lib.concatLines (
      map (line "bind") (titled ++ untitled)
      ++ map (line "bindl") media
      ++
      [
        # Mod+drag moves, Mod+right-drag resizes, as in niri
        "mousebind=SUPER,btn_left,moveresize,curmove"
        "mousebind=SUPER,btn_right,moveresize,curresize"
      ]
    )
  );
}
