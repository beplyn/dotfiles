{
  config,
  lib,
  pkgs,
  ...
}:

# niri's binds (niri/binds.nix) on the same keys; where sway has no
# equivalent the closest action is noted
let
  mod = "Mod4";
  Mod = k: "${mod}+${k}";
  ModShift = k: "${mod}+Shift+${k}";
  ModCtrl = k: "${mod}+Ctrl+${k}";
  ModAlt = k: "${mod}+Alt+${k}";

  wezterm = lib.getExe config.programs.wezterm.package;
  walker = lib.getExe config.services.walker.package;
  # qs ipc call as a command string
  ipc = target: fn: args: lib.escapeShellArgs (config.lib.haku.ipc target fn ++ args);
  # through hypridle, whose lock_cmd skips an already running hyprlock
  loginctl = lib.getExe' pkgs.systemd "loginctl";
  wpctl = lib.getExe' pkgs.wireplumber "wpctl";
  brightnessctl = lib.getExe pkgs.brightnessctl;

  exec = cmd: "exec ${cmd}";

  # niri's move-column-to-workspace follows the window
  moveTo = ws: "move container to workspace ${ws}, workspace ${ws}";

  # every bind titled, by section, for the hotkey overlay (Mod+/), as in niri's
  show = key: title: command: { inherit key title command; };
  # work while locked
  locked = b: b // { flags = "--locked "; };
  sections =
  [
    {
      name = "Apps and shell";
      binds =
      [
        (show (Mod "Return") "Terminal" (exec wezterm))
        (show (Mod "space") "Launcher" (exec walker))
        (show (Mod "v") "Clipboard" (exec (ipc "panels" "toggle" [ "clipboard" ])))
        (show (Mod "a") "Control center" (exec (ipc "panels" "toggle" [ "control" ])))
        (show (Mod "d") "Dashboard" (exec (ipc "panels" "toggle" [ "dashboard" ])))
        (show (Mod "n") "Notification center" (exec (ipc "notifications" "toggle" [ ])))
        (show (ModShift "n") "Toggle do not disturb" (exec (ipc "notifications" "toggleDnd" [ ])))
        (show (ModShift "r") "Screen recorder" (exec (ipc "recorder" "toggle" [ ])))
        (show (Mod "w") "Wallpaper picker" (exec (lib.getExe pkgs.waypaper)))
        (show "Print" "Screenshot area" (exec "screenshot area"))
        (show (ModShift "s") "Screenshot area" (exec "screenshot area"))
        (show "Shift+Print" "Screenshot screen" (exec "screenshot output"))
      ];
    }
    {
      name = "Session";
      binds =
      [
        (show (Mod "q") "Close window" "kill")
        # niri asks before quitting too
        (show (ModShift "e") "Quit sway" (exec "swaynag -t warning -m 'Quit sway?' -B 'Quit' 'swaymsg exit'"))
        (show (ModAlt "l") "Lock screen" (exec "${loginctl} lock-session"))
        (show (Mod "x") "Power menu" (exec (ipc "panels" "toggle" [ "power" ])))
        (show (Mod "slash") "Show hotkeys" (exec (ipc "panels" "toggle" [ "hotkeys" ])))
        # no overview; jump to the previous workspace
        (show (Mod "Tab") "Previous workspace" "workspace back_and_forth")
      ];
    }
    {
      name = "Window sizing";
      binds =
      [
        # no maximize-column; tabbed fills the workspace and keeps the bar
        (show (Mod "f") "Toggle tabbed layout" "layout toggle tabbed split")
        (show (ModShift "f") "Fullscreen window" "fullscreen toggle")
        (show (ModAlt "x") "Toggle floating" "floating toggle")
        (show (Mod "r") "Resize mode" "mode resize")
        (show (Mod "minus") "Shrink width" "resize shrink width 10 ppt")
        (show (Mod "equal") "Grow width" "resize grow width 10 ppt")
        # "+" is on equal
        (show (ModShift "equal") "Grow width" "resize grow width 10 ppt")
        (show (Mod "KP_Subtract") "Shrink width" "resize shrink width 10 ppt")
        (show (Mod "KP_Add") "Grow width" "resize grow width 10 ppt")
        # consume / expel: the next window opens stacked, or beside
        (show (Mod "bracketleft") "Split vertically" "splitv")
        (show (Mod "bracketright") "Split horizontally" "splith")
      ];
    }
    {
      # Mod+R: no preset widths, so a resize mode instead
      name = "Resize mode";
      mode = "resize";
      binds =
      [
        (show "h" "Shrink width" "resize shrink width 10 ppt")
        (show "l" "Grow width" "resize grow width 10 ppt")
        (show "k" "Shrink height" "resize shrink height 10 ppt")
        (show "j" "Grow height" "resize grow height 10 ppt")
        (show "Return" "Leave resize mode" "mode default")
        (show "Escape" "Leave resize mode" "mode default")
        (show (Mod "r") "Leave resize mode" "mode default")
      ];
    }
    {
      name = "Navigation";
      binds =
      [
        (show (Mod "h") "Focus left" "focus left")
        (show (Mod "l") "Focus right" "focus right")
        (show (Mod "k") "Focus up" "focus up")
        (show (Mod "j") "Focus down" "focus down")

        (show (Mod "u") "Next workspace" "workspace next_on_output")
        (show (Mod "i") "Previous workspace" "workspace prev_on_output")

        (show (ModShift "h") "Move window left" "move left")
        (show (ModShift "l") "Move window right" "move right")
        (show (ModShift "k") "Move window up" "move up")
        (show (ModShift "j") "Move window down" "move down")

        # workspaces can't be reordered; send this one to the next output
        (show (ModShift "u") "Move workspace to output right" "move workspace to output right")
        (show (ModShift "i") "Move workspace to output left" "move workspace to output left")

        (show (ModCtrl "h") "Focus output left" "focus output left")
        (show (ModCtrl "l") "Focus output right" "focus output right")

        (show (ModCtrl "u") "Move window to next workspace" (moveTo "next_on_output"))
        (show (ModCtrl "i") "Move window to previous workspace" (moveTo "prev_on_output"))
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
          (show (Mod n) "Focus workspace ${n}" "workspace number ${n}")
          (show (ModShift n) "Move window to workspace ${n}" (moveTo "number ${n}"))
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
          title = "Move window to workspace";
        }
      ];
    }
    {
      name = "Media keys";
      binds = map locked
      [
        (show "XF86AudioRaiseVolume" "Volume up" (exec "${wpctl} set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"))
        (show "XF86AudioLowerVolume" "Volume down" (exec "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
        (show "XF86AudioMute" "Mute" (exec "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle"))
        (show "XF86AudioMicMute" "Mute microphone" (exec "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
        (show "XF86MonBrightnessUp" "Brightness up" (exec "${brightnessctl} set 5%+"))
        (show "XF86MonBrightnessDown" "Brightness down" (exec "${brightnessctl} set 5%-"))
      ];
    }
    {
      # what niri has no bind for
      name = "Sway only";
      binds =
      [
        (show (Mod "t") "Cycle layout" "layout toggle splith splitv stacking tabbed")
        (show (Mod "e") "Toggle split direction" "layout toggle split")
        (show (ModShift "Tab") "Focus floating / tiling" "focus mode_toggle")
        (show (Mod "grave") "Show scratchpad" "scratchpad show")
        (show (ModShift "grave") "Send to scratchpad" "move scratchpad")
        # floating windows only
        (show (Mod "p") "Pin to all workspaces" "sticky toggle")
        (show (Mod "g") "Focus parent" "focus parent")
        (show (ModShift "g") "Focus child" "focus child")
      ];
    }
  ];

  # sway's key -> command attrs
  toAttrs = binds: lib.listToAttrs (
    map (b: lib.nameValuePair "${b.flags or ""}${b.key}" b.command) binds
  );
in
{
  # read by the quickshell hotkey overlay
  lib.haku.swayHotkeys = map
    (s:
    {
      inherit (s) name;
      binds = s.rows or (map (b: { inherit (b) key title; }) s.binds);
    })
    sections;

  wayland.windowManager.sway.config =
  {
    modifier = mod;
    terminal = wezterm;
    menu = walker;
    floating.modifier = mod;

    modes = lib.listToAttrs (
      map (s: lib.nameValuePair s.mode (toAttrs s.binds)) (lib.filter (s: s ? mode) sections)
    );
    keybindings = toAttrs (lib.concatMap (s: s.binds) (lib.filter (s: !(s ? mode)) sections));
  };
}
