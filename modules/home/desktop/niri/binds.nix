{
  config,
  lib,
  pkgs,
  ...
}:

# every bind titled, by section, for the quickshell hotkey overlay (Mod+/),
# which stands in for niri's own as in sway and mango
let
  Mod = k: "Mod+${k}";
  ModShift = k: "Mod+Shift+${k}";
  ModCtrl = k: "Mod+Ctrl+${k}";
  ModAlt = k: "Mod+Alt+${k}";

  wezterm = lib.getExe config.programs.wezterm.package;
  ipc = config.lib.haku.ipc;
  # through hypridle, whose lock_cmd skips an already running hyprlock
  loginctl = lib.getExe' pkgs.systemd "loginctl";
  wpctl = lib.getExe' pkgs.wireplumber "wpctl";
  brightnessctl = lib.getExe pkgs.brightnessctl;

  # a bind: key, title, and niri's action
  bind = key: title: action: { inherit key title action; };
  spawn = key: title: args: bind key title { spawn = args; };
  noRepeat = b: b // { repeat = false; };
  # work while locked
  media = key: title: args: spawn key title args // { allow-when-locked = true; };

  sections =
  [
    {
      name = "Apps and shell";
      binds =
      [
        (spawn (Mod "Return") "Terminal" [ wezterm ])
        (spawn (Mod "Space") "Launcher" (ipc "panels" "toggle" ++ [ "launcher" ]))
        (spawn (Mod "V") "Clipboard" (ipc "panels" "toggle" ++ [ "clipboard" ]))
        (spawn (Mod "A") "Control center" (ipc "panels" "toggle" ++ [ "control" ]))
        (spawn (Mod "D") "Dashboard" (ipc "panels" "toggle" ++ [ "dashboard" ]))
        (spawn (ModShift "C") "Calendar" config.lib.haku.calendar.open)
        (spawn (Mod "N") "Notification center" (ipc "notifications" "toggle"))
        (spawn (ModShift "N") "Toggle do not disturb" (ipc "notifications" "toggleDnd"))
        (spawn (ModShift "R") "Screen recorder" (ipc "recorder" "toggle"))
        (spawn (Mod "W") "Wallpaper picker" [ (lib.getExe pkgs.waypaper) ])
        (spawn "Print" "Screenshot area"
        [
          "screenshot"
          "area"
        ])
        (spawn (ModShift "S") "Screenshot area"
        [
          "screenshot"
          "area"
        ])
        (spawn "Shift+Print" "Screenshot screen"
        [
          "screenshot"
          "output"
        ])
      ];
    }
    {
      name = "Session";
      binds =
      [
        (noRepeat (bind (Mod "Q") "Close window" { close-window = [ ]; }))
        (bind (ModShift "E") "Quit niri" { quit = [ ]; })
        (spawn (ModAlt "L") "Lock screen" [ loginctl "lock-session" ])
        (spawn (Mod "X") "Power menu" (ipc "panels" "toggle" ++ [ "power" ]))
        (spawn (Mod "Slash") "Show hotkeys" (ipc "panels" "toggle" ++ [ "hotkeys" ]))
        (noRepeat (bind (Mod "Tab") "Overview" { toggle-overview = [ ]; }))
      ];
    }
    {
      name = "Window sizing";
      binds =
      [
        (bind (Mod "F") "Maximize column" { maximize-column = [ ]; })
        (bind (ModShift "F") "Fullscreen window" { fullscreen-window = [ ]; })
        (bind (ModAlt "X") "Toggle floating" { toggle-window-floating = [ ]; })
        (bind (Mod "R") "Cycle column width" { switch-preset-column-width = [ ]; })
        (bind (Mod "Minus") "Shrink column" { set-column-width = "-10%"; })
        (bind (Mod "Equal") "Grow column" { set-column-width = "+10%"; })
        # "+" is on Equal
        (bind (ModShift "Equal") "Grow column" { set-column-width = "+10%"; })
        (bind (Mod "KP_Subtract") "Shrink column" { set-column-width = "-10%"; })
        (bind (Mod "KP_Add") "Grow column" { set-column-width = "+10%"; })
        (bind (Mod "BracketLeft") "Consume / expel window left" { consume-or-expel-window-left = [ ]; })
        (bind (Mod "BracketRight") "Consume / expel window right" { consume-or-expel-window-right = [ ]; })
        (bind (Mod "T") "Toggle tabbed column" { toggle-column-tabbed-display = [ ]; })
      ];
    }
    {
      name = "Navigation";
      binds =
      [
        (bind (Mod "H") "Focus column left" { focus-column-left = [ ]; })
        (bind (Mod "L") "Focus column right" { focus-column-right = [ ]; })
        (bind (Mod "K") "Focus window or workspace up" { focus-window-or-workspace-up = [ ]; })
        (bind (Mod "J") "Focus window or workspace down" { focus-window-or-workspace-down = [ ]; })

        (bind (Mod "U") "Next workspace" { focus-workspace-down = [ ]; })
        (bind (Mod "I") "Previous workspace" { focus-workspace-up = [ ]; })

        (bind (ModShift "H") "Move column left" { move-column-left = [ ]; })
        (bind (ModShift "L") "Move column right" { move-column-right = [ ]; })
        (bind (ModShift "K") "Move window up" { move-window-up = [ ]; })
        (bind (ModShift "J") "Move window down" { move-window-down = [ ]; })

        (bind (ModShift "U") "Move workspace down" { move-workspace-down = [ ]; })
        (bind (ModShift "I") "Move workspace up" { move-workspace-up = [ ]; })

        (bind (ModCtrl "H") "Focus monitor left" { focus-monitor-left = [ ]; })
        (bind (ModCtrl "L") "Focus monitor right" { focus-monitor-right = [ ]; })

        (bind (ModCtrl "U") "Move column to next workspace" { move-column-to-workspace-down = [ ]; })
        (bind (ModCtrl "I") "Move column to previous workspace" { move-column-to-workspace-up = [ ]; })
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
          (bind (Mod n) "Focus workspace ${n}" { focus-workspace = i; })
          (bind (ModShift n) "Move column to workspace ${n}" { move-column-to-workspace = i; })
        ])
        (lib.range 1 9);
      # one overlay row each
      rows =
      [
        {
          key = Mod "1-9";
          title = "Focus workspace";
        }
        {
          key = ModShift "1-9";
          title = "Move column to workspace";
        }
      ];
    }
    {
      name = "Media keys";
      binds =
      [
        (media "XF86AudioRaiseVolume" "Volume up"
        [
          wpctl
          "set-volume"
          "-l"
          "1.0"
          "@DEFAULT_AUDIO_SINK@"
          "5%+"
        ])
        (media "XF86AudioLowerVolume" "Volume down"
        [
          wpctl
          "set-volume"
          "@DEFAULT_AUDIO_SINK@"
          "5%-"
        ])
        (media "XF86AudioMute" "Mute"
        [
          wpctl
          "set-mute"
          "@DEFAULT_AUDIO_SINK@"
          "toggle"
        ])
        (media "XF86AudioMicMute" "Mute microphone"
        [
          wpctl
          "set-mute"
          "@DEFAULT_AUDIO_SOURCE@"
          "toggle"
        ])
        (media "XF86MonBrightnessUp" "Brightness up"
        [
          brightnessctl
          "set"
          "5%+"
        ])
        (media "XF86MonBrightnessDown" "Brightness down"
        [
          brightnessctl
          "set"
          "5%-"
        ])
      ];
    }
  ];
in
{
  # read by the quickshell hotkey overlay
  lib.haku.niriHotkeys = map
    (s:
    {
      inherit (s) name;
      binds = s.rows or (map (b: { inherit (b) key title; }) s.binds);
    })
    sections;

  # the overlay replaces niri's own
  programs.niri.settings.hotkey-overlay.skip-at-startup = true;

  programs.niri.settings.binds = lib.listToAttrs (
    map
      (b: lib.nameValuePair b.key (removeAttrs b [ "key" "title" ] // { hotkey-overlay.title = b.title; }))
      (lib.concatMap (s: s.binds) sections)
  );
}
