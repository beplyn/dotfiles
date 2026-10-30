{
  config,
  lib,
  pkgs,
  ...
}:
let
  Mod = k: "Mod+${k}";
  ModShift = k: "Mod+Shift+${k}";
  ModCtrl = k: "Mod+Ctrl+${k}";

  kitty = lib.getExe config.programs.kitty.package;
  walker = lib.getExe config.services.walker.package;
  ipc = config.lib.haku.ipc;
  hyprlock = lib.getExe config.programs.hyprlock.package;
  wpctl = lib.getExe' pkgs.wireplumber "wpctl";
  brightnessctl = lib.getExe pkgs.brightnessctl;

  # Every bind is listed in the hotkey overlay (Mod+Shift+/) under a title,
  # except basic navigation, which is hidden explicitly because niri would
  # otherwise list it by default.
  show = title: action:
  {
    inherit action;
    hotkey-overlay.title = title;
  };
  hide = action:
  {
    inherit action;
    hotkey-overlay.hidden = true;
  };
  spawn = title: args: show title { spawn = args; };

  # Media keys keep working on the lock screen.
  media = args: hide { spawn = args; } // { allow-when-locked = true; };

  # Mod+1..9 focuses a workspace, Mod+Shift+1..9 sends the column there.
  workspaces = lib.listToAttrs (
    lib.concatMap
      (i:
      [
        {
          name = Mod (toString i);
          value = hide { focus-workspace = i; };
        }
        {
          name = ModShift (toString i);
          value = hide { move-column-to-workspace = i; };
        }
      ])
      (lib.range 1 9)
  );
in
{
  programs.niri.settings.binds = workspaces //
  {
    # --- apps and shell ---------------------------------------------------
    ${Mod "Return"} = spawn "Terminal" [ kitty ];
    ${Mod "Space"} = spawn "Launcher" [ walker ];
    ${Mod "V"} = spawn "Clipboard history"
    [
      walker
      "-m"
      "clipboard"
    ];
    ${Mod "A"} = spawn "Control center" (ipc "panels" "toggle" ++ [ "control" ]);
    ${Mod "D"} = spawn "Dashboard" (ipc "panels" "toggle" ++ [ "dashboard" ]);
    ${Mod "N"} = spawn "Notification center" (ipc "notifications" "toggle");
    ${ModShift "N"} = spawn "Toggle do not disturb" (ipc "notifications" "toggleDnd");
    ${ModShift "R"} = spawn "Screen recorder" (ipc "recorder" "toggle");
    ${Mod "W"} = spawn "Wallpaper picker" [ (lib.getExe pkgs.waypaper) ];
    "Print" = spawn "Screenshot area"
    [
      "screenshot"
      "area"
    ];
    ${ModShift "S"} = spawn "Screenshot area"
    [
      "screenshot"
      "area"
    ];
    "Shift+Print" = spawn "Screenshot screen"
    [
      "screenshot"
      "output"
    ];

    # --- session ----------------------------------------------------------
    ${Mod "Q"} = show "Close window" { close-window = [ ]; } // { repeat = false; };
    ${ModShift "E"} = show "Quit niri" { quit = [ ]; };
    "Mod+Alt+L" = spawn "Lock screen" [ hyprlock ];
    ${ModShift "Slash"} = show "Show hotkeys" { show-hotkey-overlay = [ ]; };
    ${Mod "Tab"} = show "Overview" { toggle-overview = [ ]; } // { repeat = false; };

    # --- window sizing ----------------------------------------------------
    ${Mod "F"} = show "Maximize column" { maximize-column = [ ]; };
    ${ModShift "F"} = show "Fullscreen window" { fullscreen-window = [ ]; };
    "Mod+Alt+X" = show "Toggle floating" { toggle-window-floating = [ ]; };
    ${Mod "R"} = show "Cycle column width" { switch-preset-column-width = [ ]; };
    # niri matches the unshifted key, so "+" is bound on Equal (Shift+= on
    # gb). The Shift and keypad variants are aliases kept out of the list.
    ${Mod "Minus"} = show "Shrink column" { set-column-width = "-10%"; };
    ${Mod "Equal"} = show "Grow column" { set-column-width = "+10%"; };
    ${ModShift "Equal"} = hide { set-column-width = "+10%"; };
    ${Mod "KP_Subtract"} = hide { set-column-width = "-10%"; };
    ${Mod "KP_Add"} = hide { set-column-width = "+10%"; };

    ${Mod "BracketLeft"} = show "Consume / expel window left" { consume-or-expel-window-left = [ ]; };
    ${Mod "BracketRight"} = show "Consume / expel window right"
    {
      consume-or-expel-window-right = [ ];
    };

    # --- navigation (hidden) ----------------------------------------------
    ${Mod "H"} = hide { focus-column-left = [ ]; };
    ${Mod "L"} = hide { focus-column-right = [ ]; };
    ${Mod "K"} = hide { focus-window-or-workspace-up = [ ]; };
    ${Mod "J"} = hide { focus-window-or-workspace-down = [ ]; };

    ${Mod "U"} = hide { focus-workspace-down = [ ]; };
    ${Mod "I"} = hide { focus-workspace-up = [ ]; };

    ${ModShift "H"} = hide { move-column-left = [ ]; };
    ${ModShift "L"} = hide { move-column-right = [ ]; };
    ${ModShift "K"} = hide { move-window-up = [ ]; };
    ${ModShift "J"} = hide { move-window-down = [ ]; };

    ${ModShift "U"} = hide { move-workspace-down = [ ]; };
    ${ModShift "I"} = hide { move-workspace-up = [ ]; };

    ${ModCtrl "H"} = hide { focus-monitor-left = [ ]; };
    ${ModCtrl "L"} = hide { focus-monitor-right = [ ]; };

    ${ModCtrl "U"} = hide { move-column-to-workspace-down = [ ]; };
    ${ModCtrl "I"} = hide { move-column-to-workspace-up = [ ]; };

    # --- media keys (hidden) ----------------------------------------------
    "XF86AudioRaiseVolume" = media
    [
      wpctl
      "set-volume"
      "-l"
      "1.0"
      "@DEFAULT_AUDIO_SINK@"
      "5%+"
    ];
    "XF86AudioLowerVolume" = media
    [
      wpctl
      "set-volume"
      "@DEFAULT_AUDIO_SINK@"
      "5%-"
    ];
    "XF86AudioMute" = media
    [
      wpctl
      "set-mute"
      "@DEFAULT_AUDIO_SINK@"
      "toggle"
    ];
    "XF86AudioMicMute" = media
    [
      wpctl
      "set-mute"
      "@DEFAULT_AUDIO_SOURCE@"
      "toggle"
    ];
    "XF86MonBrightnessUp" = media
    [
      brightnessctl
      "set"
      "5%+"
    ];
    "XF86MonBrightnessDown" = media
    [
      brightnessctl
      "set"
      "5%-"
    ];
  };
}
