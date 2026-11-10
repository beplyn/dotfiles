{
  config,
  lib,
  pkgs,
  ...
}:

# niri-style binds, with the scrolling layout for its columns; where
# Hyprland has no equivalent the closest action is noted. binds.lua turns
# each into an hl.bind.
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
  # a scrolling layout message, which other layouts reject; there the
  # tiling dispatcher instead, or nothing
  scrolling = msg: tiling: { inherit msg tiling; };
  scroll = "haku.scrolling";
  # dwindle has no columns: the window by this many pixels
  resizeBy = x:
  {
    dsp = "window.resize";
    arg =
    {
      inherit x;
      y = 0;
      relative = true;
    };
  };

  # niri asks before quitting too; hyprshutdown closes apps first
  quit = "[ \"$(printf 'Quit\\nCancel\\n' | ${walker} -d -p 'Quit Hyprland?')\" = Quit ] && ${hyprshutdown} -t 'Quitting Hyprland…'";

  # every bind titled, by section, for the hotkey overlay (Mod+/), as in niri's
  show = title: b: b // { inherit title; };
  # held keys repeat, as in niri, but for these
  noRepeat = b: b // { repeat = false; };
  # work while locked
  locked = b: b // { opts = { locked = true; }; };
  sections =
  [
    {
      name = "Apps and shell";
      binds =
      [
        (show "Terminal" (Mod "Return" exec wezterm))
        (show "Launcher" (Mod "space" exec (ipc "panels" "toggle" [ "launcher" ])))
        (show "Clipboard" (Mod "v" exec (ipc "panels" "toggle" [ "clipboard" ])))
        (show "Control center" (Mod "a" exec (ipc "panels" "toggle" [ "control" ])))
        (show "Dashboard" (Mod "d" exec (ipc "panels" "toggle" [ "dashboard" ])))
        (show "Notification center" (Mod "n" exec (ipc "notifications" "toggle" [ ])))
        (show "Toggle do not disturb" (ModShift "n" exec (ipc "notifications" "toggleDnd" [ ])))
        (show "Screen recorder" (ModShift "r" exec (ipc "recorder" "toggle" [ ])))
        # on hyprpaper (quickshell/wallpaper.nix)
        (show "Wallpaper picker" (Mod "w" exec "waypaper"))
        (show "Screenshot area" (None "Print" exec "screenshot area"))
        (show "Screenshot area" (ModShift "s" exec "screenshot area"))
        (show "Screenshot screen" (Shift "Print" exec "screenshot output"))
      ];
    }
    {
      name = "Session";
      binds =
      [
        (show "Close window" (noRepeat (Mod "q" "window.close" null)))
        (show "Quit Hyprland" (noRepeat (ModShift "e" exec quit)))
        (show "Lock screen" (ModAlt "l" exec "${loginctl} lock-session"))
        (show "Power menu" (Mod "x" exec (ipc "panels" "toggle" [ "power" ])))
        (show "Show hotkeys" (Mod "slash" exec (ipc "panels" "toggle" [ "hotkeys" ])))
        # this monitor's workspaces, Quickshell's while hyprtasking is off
        # (plugins.nix); hyprtasking's was (Mod "Tab" "haku.overview" null)
        (show "Overview" (noRepeat (Mod "Tab" exec (ipc "panels" "toggle" [ "overview" ]))))
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
        (show "Cycle column width" (Mod "r" scroll (scrolling "colresize +conf" null)))
        # set-column-width ±10%
        (show "Shrink column" (Mod "minus" scroll (scrolling "colresize -0.1" (resizeBy (-100)))))
        (show "Grow column" (Mod "equal" scroll (scrolling "colresize +0.1" (resizeBy 100))))
        # "+" is on equal
        (show "Grow column" (ModShift "equal" scroll (scrolling "colresize +0.1" (resizeBy 100))))
        (show "Shrink column" (Mod "KP_Subtract" scroll (scrolling "colresize -0.1" (resizeBy (-100)))))
        (show "Grow column" (Mod "KP_Add" scroll (scrolling "colresize +0.1" (resizeBy 100))))
        (show "Consume / expel window left" (Mod "bracketleft" scroll (scrolling "consume_or_expel prev" null)))
        (show "Consume / expel window right" (Mod "bracketright" scroll (scrolling "consume_or_expel next" null)))
      ];
    }
    {
      name = "Navigation";
      binds =
      [
        (show "Focus left" (Mod "h" "focus" { direction = "left"; }))
        (show "Focus right" (Mod "l" "focus" { direction = "right"; }))
        (show "Focus window or workspace up" (Mod "k" "haku.focus_or_workspace" "up"))
        (show "Focus window or workspace down" (Mod "j" "haku.focus_or_workspace" "down"))

        # on this monitor, as niri's; hyprsplit (workspaces.lua)
        (show "Next workspace" (Mod "u" "split.focus" { workspace = "+1"; }))
        (show "Previous workspace" (Mod "i" "split.focus" { workspace = "-1"; }))

        (show "Move column left" (ModShift "h" "haku.move_column" "left"))
        (show "Move column right" (ModShift "l" "haku.move_column" "right"))
        (show "Move window up" (ModShift "k" "window.move" { direction = "up"; }))
        (show "Move window down" (ModShift "j" "window.move" { direction = "down"; }))

        # workspaces can't be reordered; send the workspace to the next monitor
        (show "Move workspace to monitor right" (ModShift "u" "workspace.move" { monitor = "+1"; }))
        (show "Move workspace to monitor left" (ModShift "i" "workspace.move" { monitor = "-1"; }))

        (show "Focus monitor left" (ModCtrl "h" "focus" { monitor = "l"; }))
        (show "Focus monitor right" (ModCtrl "l" "focus" { monitor = "r"; }))

        # follows the window, like move-column-to-workspace
        (show "Move column to next workspace" (ModCtrl "u" "haku.move_column_to_workspace" { offset = 1; }))
        (show "Move column to previous workspace" (ModCtrl "i" "haku.move_column_to_workspace" { offset = -1; }))
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
          (show "Focus workspace ${n}" (Mod n "split.focus" { workspace = i; }))
          (show "Move column to workspace ${n}" (ModShift n "haku.move_column_to_workspace" { workspace = i; }))
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
          title = "Move column to workspace";
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
      # beyond the niri-style set
      name = "Hyprland";
      # toggles, which a held key would flip back and forth
      repeat = false;
      binds =
      [
        # scrolling columns or classic tiling
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
        (show "Dropdown terminal" (ModAlt "Return" exec "pypr toggle term"))
        (show "Zoom" (ModAlt "z" exec "pypr zoom"))
        # the palette shader (palette.glsl)
        (show "Toggle palette shader" (ModAlt "s" exec "hyprshade toggle palette"))
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
  luaBind = s: b:
  {
    key = lib.concatStringsSep " + " (b.mods ++ [ b.key ]);
    inherit (b) dsp arg;
    opts = { repeating = b.repeat or s.repeat or true; } // b.opts or { };
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
    (lib.concatMap (s: map (luaBind s) s.binds) sections);
}
