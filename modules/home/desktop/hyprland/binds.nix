{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  Mod = key: "SUPER, ${key}";
  ModShift = key: "SUPER SHIFT, ${key}";
  ModCtrl = key: "SUPER CTRL, ${key}";
  ModAlt = key: "SUPER ALT, ${key}";

  wezterm = lib.getExe config.programs.wezterm.package;
  walker = lib.getExe config.services.walker.package;
  hyprctl = lib.getExe' osConfig.programs.hyprland.package "hyprctl";
  loginctl = lib.getExe' pkgs.systemd "loginctl";
  wpctl = lib.getExe' pkgs.wireplumber "wpctl";
  brightnessctl = lib.getExe pkgs.brightnessctl;
  hyprshot = lib.getExe pkgs.hyprshot;
  hyprpicker = lib.getExe pkgs.hyprpicker;
  hyprprop = lib.getExe pkgs.hyprprop;
  ipc =
    target: fn: args:
    lib.escapeShellArgs (config.lib.haku.ipc target fn ++ args);
  exec = command: "exec,${command}";

  show = key: title: command: {
    inherit key title;
    bind = "${key}, ${command}";
  };
  locked = bind: bind;
  sections = [
    {
      name = "Apps and shell";
      binds = [
        (show (Mod "RETURN") "Terminal" (exec wezterm))
        (show (Mod "SPACE") "Launcher" (exec walker))
        (show (Mod "V") "Clipboard history" (exec "${walker} -m clipboard"))
        (show (Mod "A") "Control center" (exec (ipc "panels" "toggle" [ "control" ])))
        (show (Mod "D") "Dashboard" (exec (ipc "panels" "toggle" [ "dashboard" ])))
        (show (Mod "N") "Notification center" (exec (ipc "notifications" "toggle" [ ])))
        (show (ModShift "N") "Toggle do not disturb" (exec (ipc "notifications" "toggleDnd" [ ])))
        (show (ModShift "R") "Screen recorder" (exec (ipc "recorder" "toggle" [ ])))
        (show (Mod "W") "Wallpaper picker" (exec "${lib.getExe pkgs.waypaper} --backend hyprpaper"))
        (show "Print" "Screenshot area" (exec "${hyprshot} -m region"))
        (show (ModShift "S") "Screenshot area" (exec "${hyprshot} -m region"))
        (show "SHIFT, Print" "Screenshot screen" (exec "${hyprshot} -m output"))
      ];
    }
    {
      name = "Session";
      binds = [
        (show (Mod "Q") "Close window" "killactive,")
        (show (ModShift "E") "Quit Hyprland" (exec "${hyprctl} dispatch exit"))
        (show (ModAlt "L") "Lock screen" (exec "${loginctl} lock-session"))
        (show (Mod "X") "Power menu" (exec (ipc "panels" "toggle" [ "power" ])))
        (show (Mod "SLASH") "Show hotkeys" (exec (ipc "panels" "toggle" [ "hotkeys" ])))
        (show (Mod "TAB") "Overview" "togglespecialworkspace,overview")
      ];
    }
    {
      name = "Window sizing";
      binds = [
        (show (Mod "F") "Maximize window" "fullscreenstate,1 0")
        (show (ModShift "F") "Fullscreen window" "fullscreen,1")
        (show (ModAlt "X") "Toggle floating" "togglefloating,")
        (show (Mod "R") "Cycle layout preset" "alterzorder,top")
        (show (Mod "MINUS") "Shrink width" "resizeactive,-100 0")
        (show (Mod "EQUAL") "Grow width" "resizeactive,100 0")
        (show (ModShift "EQUAL") "Grow width" "resizeactive,100 0")
        (show (Mod "KP_SUBTRACT") "Shrink width" "resizeactive,-100 0")
        (show (Mod "KP_ADD") "Grow width" "resizeactive,100 0")
      ];
    }
    {
      name = "Navigation";
      binds = [
        (show (Mod "H") "Focus left" "movefocus,l")
        (show (Mod "L") "Focus right" "movefocus,r")
        (show (Mod "K") "Focus up" "movefocus,u")
        (show (Mod "J") "Focus down" "movefocus,d")
        (show (Mod "U") "Next workspace" "workspace,e+1")
        (show (Mod "I") "Previous workspace" "workspace,e-1")
        (show (ModShift "H") "Move window left" "movewindow,l")
        (show (ModShift "L") "Move window right" "movewindow,r")
        (show (ModShift "K") "Move window up" "movewindow,u")
        (show (ModShift "J") "Move window down" "movewindow,d")
        (show (ModShift "U") "Move workspace to monitor right" "movecurrentworkspacetomonitor,+1")
        (show (ModShift "I") "Move workspace to monitor left" "movecurrentworkspacetomonitor,-1")
        (show (ModCtrl "H") "Focus monitor left" "focusmonitor,l")
        (show (ModCtrl "L") "Focus monitor right" "focusmonitor,r")
        (show (ModCtrl "U") "Move window to next workspace" "movetoworkspace,e+1")
        (show (ModCtrl "I") "Move window to previous workspace" "movetoworkspace,e-1")
      ];
    }
    {
      name = "Workspaces";
      binds = lib.concatMap (
        i:
        let
          n = toString i;
        in
        [
          (show (Mod n) "Focus workspace ${n}" "workspace,${n}")
          (show (ModShift n) "Move window to workspace ${n}" "movetoworkspace,${n}")
        ]
      ) (lib.range 1 9);
      rows = [
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
      binds = map (b: b // { bind = locked b.bind; }) [
        (show "XF86AudioRaiseVolume" "Volume up" (
          exec "${wpctl} set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"
        ))
        (show "XF86AudioLowerVolume" "Volume down" (exec "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
        (show "XF86AudioMute" "Mute" (exec "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle"))
        (show "XF86AudioMicMute" "Mute microphone" (exec "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
        (show "XF86MonBrightnessUp" "Brightness up" (exec "${brightnessctl} set 5%+"))
        (show "XF86MonBrightnessDown" "Brightness down" (exec "${brightnessctl} set 5%-"))
      ];
    }
    {
      name = "Hyprland only";
      binds = [
        (show (Mod "T") "Toggle pseudotiling" "togglepseudo,")
        (show (Mod "G") "Toggle split direction" "togglesplit,")
        (show (ModShift "TAB") "Focus previous window" "cyclenext,prev")
        (show (Mod "GRAVE") "Show special workspace" "togglespecialworkspace,")
        (show (ModShift "GRAVE") "Move window to special workspace" "movetoworkspace,special")
        (show (Mod "P") "Pin window" "pin,")
        (show (ModShift "P") "Toggle group" "togglegroup,")
        (show (Mod "O") "Toggle layout orientation" "togglesplit,")
        (show (ModShift "O") "Toggle group lock" "lockgroups,toggle")
        (show (Mod "Y") "Pick color" (exec "${hyprpicker} -a"))
        (show (ModShift "Y") "Inspect window" (exec hyprprop))
      ];
    }
  ];

  overlayKey =
    bind:
    let
      parts = lib.splitString ", " bind.key;
      key = lib.toLower (lib.last parts);
      modifiers = lib.replaceStrings [ "SUPER" "SHIFT" "CTRL" "ALT" ] [ "Super" "Shift" "Ctrl" "Alt" ] (
        builtins.head parts
      );
    in
    if builtins.length parts == 1 then
      key
    else
      lib.concatStringsSep "+" [
        modifiers
        key
      ];
in
{
  lib.haku.hyprlandHotkeys = map (section: {
    inherit (section) name;
    binds =
      section.rows or (map (bind: {
        key = overlayKey bind;
        inherit (bind) title;
      }) section.binds);
  }) sections;

  wayland.windowManager.hyprland.settings = {
    bind = lib.concatMap (section: map (bind: bind.bind) section.binds) (
      lib.filter (section: !(section.name == "Media keys")) sections
    );
    bindl = lib.concatMap (section: map (bind: bind.bind) section.binds) (
      lib.filter (section: section.name == "Media keys") sections
    );
  };
}
