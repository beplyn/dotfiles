{
  config,
  lib,
  pkgs,
  ...
}:

# niri's binds (niri/binds.nix) on the same keys, with the scrolling layout
# standing in for niri's columns; where Hyprland has no equivalent the
# closest action is noted. binds.lua turns each into an hl.bind.
let
  wezterm = lib.getExe config.programs.wezterm.package;
  walker = lib.getExe config.services.walker.package;
  # qs ipc call as a command string
  ipc = target: fn: args: lib.escapeShellArgs (config.lib.haku.ipc target fn ++ args);
  # through hypridle, whose lock_cmd skips an already running hyprlock
  loginctl = lib.getExe' pkgs.systemd "loginctl";
  wpctl = lib.getExe' pkgs.wireplumber "wpctl";
  brightnessctl = lib.getExe pkgs.brightnessctl;
  hyprshutdown = lib.getExe pkgs.hyprshutdown;

  # a bind: modifiers, key, an hl.dsp dispatcher by path (or a haku.*
  # function from binds.lua) and its argument
  bind = mods: key: dsp: arg: { inherit mods key dsp arg; };
  Mod = bind [ "SUPER" ];
  ModShift = bind [ "SUPER" "SHIFT" ];
  ModCtrl = bind [ "SUPER" "CTRL" ];
  ModAlt = bind [ "SUPER" "ALT" ];
  None = bind [ ];
  Shift = bind [ "SHIFT" ];
  exec = "exec_cmd";
  layout = "layout";

  # niri asks before quitting too; hyprshutdown closes apps first
  quit = "[ \"$(printf 'Quit\\nCancel\\n' | ${walker} -d -p 'Quit Hyprland?')\" = Quit ] && ${hyprshutdown} -t 'Quitting Hyprland…'";

  # every bind titled, by section, for the hotkey overlay (Mod+/), as in niri's
  show = title: b: b // { inherit title; };
  # work while locked, repeat while held
  locked = b: b // { opts = { locked = true; repeating = true; }; };
  repeating = b: b // { opts = { repeating = true; }; };
  sections =
  [
    {
      name = "Apps and shell";
      binds =
      [
        (show "Terminal" (Mod "Return" exec wezterm))
        (show "Launcher" (Mod "space" exec walker))
        (show "Clipboard history" (Mod "v" exec "${walker} -m clipboard"))
        (show "Control center" (Mod "a" exec (ipc "panels" "toggle" [ "control" ])))
        (show "Dashboard" (Mod "d" exec (ipc "panels" "toggle" [ "dashboard" ])))
        (show "Notification center" (Mod "n" exec (ipc "notifications" "toggle" [ ])))
        (show "Toggle do not disturb" (ModShift "n" exec (ipc "notifications" "toggleDnd" [ ])))
        (show "Screen recorder" (ModShift "r" exec (ipc "recorder" "toggle" [ ])))
        # hyprpaper, with its own waypaper config (quickshell/wallpaper.nix)
        (show "Wallpaper picker" (Mod "w" exec "waypaper-hyprland"))
        (show "Screenshot area" (None "Print" exec "screenshot area"))
        (show "Screenshot area" (ModShift "s" exec "screenshot area"))
        (show "Screenshot screen" (Shift "Print" exec "screenshot output"))
      ];
    }
    {
      name = "Session";
      binds =
      [
        (show "Close window" (Mod "q" "window.close" null))
        (show "Quit Hyprland" (ModShift "e" exec quit))
        (show "Lock screen" (ModAlt "l" exec "${loginctl} lock-session"))
        (show "Power menu" (Mod "x" exec (ipc "panels" "toggle" [ "power" ])))
        (show "Show hotkeys" (Mod "slash" exec (ipc "panels" "toggle" [ "hotkeys" ])))
        # the scrolling layout zoomed out to every column
        (show "Overview" (Mod "Tab" "haku.overview" null))
      ];
    }
    {
      name = "Window sizing";
      binds =
      [
        # maximize-column: the window fills the screen, keeping gaps and bar
        (show "Maximize window" (Mod "f" "window.fullscreen" { mode = "maximized"; }))
        (show "Fullscreen window" (ModShift "f" "window.fullscreen" { mode = "fullscreen"; }))
        (show "Toggle floating" (ModAlt "x" "window.float" { action = "toggle"; }))
        (show "Cycle column width" (Mod "r" layout "colresize +conf"))
        # set-column-width ±10%
        (show "Shrink column" (repeating (Mod "minus" layout "colresize -0.1")))
        (show "Grow column" (repeating (Mod "equal" layout "colresize +0.1")))
        # "+" is on equal
        (show "Grow column" (repeating (ModShift "equal" layout "colresize +0.1")))
        (show "Shrink column" (repeating (Mod "KP_Subtract" layout "colresize -0.1")))
        (show "Grow column" (repeating (Mod "KP_Add" layout "colresize +0.1")))
        (show "Consume / expel window left" (Mod "bracketleft" layout "consume_or_expel prev"))
        (show "Consume / expel window right" (Mod "bracketright" layout "consume_or_expel next"))
      ];
    }
    {
      name = "Navigation";
      binds =
      [
        (show "Focus left" (Mod "h" "focus" { direction = "left"; }))
        (show "Focus right" (Mod "l" "focus" { direction = "right"; }))
        (show "Focus up" (Mod "k" "focus" { direction = "up"; }))
        (show "Focus down" (Mod "j" "focus" { direction = "down"; }))

        # r±1 reaches the empty workspace past the last, like niri's
        (show "Next workspace" (Mod "u" "focus" { workspace = "r+1"; }))
        (show "Previous workspace" (Mod "i" "focus" { workspace = "r-1"; }))

        (show "Move window left" (ModShift "h" "window.move" { direction = "left"; }))
        (show "Move window right" (ModShift "l" "window.move" { direction = "right"; }))
        (show "Move window up" (ModShift "k" "window.move" { direction = "up"; }))
        (show "Move window down" (ModShift "j" "window.move" { direction = "down"; }))

        # workspaces can't be reordered; send the workspace to the next monitor
        (show "Move workspace to monitor right" (ModShift "u" "workspace.move" { monitor = "+1"; }))
        (show "Move workspace to monitor left" (ModShift "i" "workspace.move" { monitor = "-1"; }))

        (show "Focus monitor left" (ModCtrl "h" "focus" { monitor = "l"; }))
        (show "Focus monitor right" (ModCtrl "l" "focus" { monitor = "r"; }))

        # follows the window, like move-column-to-workspace
        (show "Move window to next workspace" (ModCtrl "u" "window.move" { workspace = "r+1"; }))
        (show "Move window to previous workspace" (ModCtrl "i" "window.move" { workspace = "r-1"; }))
      ];
    }
    {
      name = "Workspaces";
      binds = lib.concatMap
        (i:
        let
          n = toString i;
        in
        [
          (show "Focus workspace ${n}" (Mod n "focus" { workspace = i; }))
          (show "Move window to workspace ${n}" (ModShift n "window.move" { workspace = i; }))
        ])
        (lib.range 1 9);
      # one overlay row each
      rows =
      [
        {
          key = "Super+1-9";
          title = "Focus workspace";
        }
        {
          key = "Super+Shift+1-9";
          title = "Move window to workspace";
        }
      ];
    }
    {
      name = "Media keys";
      binds = map locked
      [
        (show "Volume up" (None "XF86AudioRaiseVolume" exec "${wpctl} set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"))
        (show "Volume down" (None "XF86AudioLowerVolume" exec "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
        (show "Mute" (None "XF86AudioMute" exec "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle"))
        (show "Mute microphone" (None "XF86AudioMicMute" exec "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
        (show "Brightness up" (None "XF86MonBrightnessUp" exec "${brightnessctl} set 5%+"))
        (show "Brightness down" (None "XF86MonBrightnessDown" exec "${brightnessctl} set 5%-"))
      ];
    }
    {
      # what niri has no bind for, on the keys mango uses for its own
      name = "Hyprland only";
      binds =
      [
        # niri's columns or classic tiling, as mango's Mod+T cycles its layouts
        (show "Toggle scrolling / tiling" (Mod "t" "haku.cycle_layout" [ "scrolling" "dwindle" ]))
        (show "Cycle windows" (ModShift "Tab" "window.cycle_next" { next = false; }))
        (show "Show scratchpad" (Mod "grave" "workspace.toggle_special" "scratch"))
        (show "Send to scratchpad" (ModShift "grave" "window.move" { workspace = "special:scratch"; follow = false; }))
        (show "Center floating window" (Mod "o" "window.center" null))
        (show "Pin floating window" (Mod "p" "window.pin" null))
        (show "Toggle group" (Mod "g" "group.toggle" null))
        (show "Lock groups" (ModShift "g" "group.lock" { action = "toggle"; }))
        (show "Previous in group" (Mod "comma" "group.prev" null))
        (show "Next in group" (Mod "period" "group.next" null))
        (show "Pick colour" (Mod "y" exec "hyprpicker -a"))
        (show "System info" (ModShift "y" exec "hyprsysteminfo"))
        (show "Audio mixer" (ModAlt "a" exec "hyprpwcenter"))
        (show "Toggle night light" (ModAlt "n" "haku.night_light" 4000))
      ];
    }
  ];

  # SUPER, SHIFT + slash -> Super+Shift+slash, as the overlay reads keys
  modName =
  {
    SUPER = "Super";
    SHIFT = "Shift";
    CTRL = "Ctrl";
    ALT = "Alt";
  };
  overlayKey = b: lib.concatStringsSep "+" (map (m: modName.${m}) b.mods ++ [ b.key ]);
  luaBind = b:
  {
    key = lib.concatStringsSep " + " (b.mods ++ [ b.key ]);
    inherit (b) dsp arg;
    opts = b.opts or { };
  };
in
{
  # read by the quickshell hotkey overlay
  lib.haku.hyprlandHotkeys = map
    (s:
    {
      inherit (s) name;
      binds = s.rows or (map
        (b:
        {
          key = overlayKey b;
          inherit (b) title;
        })
        s.binds);
    })
    sections;

  wayland.windowManager.hyprland.extraLuaFiles = config.lib.haku.hyprlandData "binds"
    (map luaBind (lib.concatMap (s: s.binds) sections));
}
