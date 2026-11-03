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
  # work while locked
  media = k: "--locked ${k}";

  # niri's move-column-to-workspace follows the window
  moveTo = ws: "move container to workspace ${ws}, workspace ${ws}";

  # titled binds, by section, for the hotkey overlay (Mod+/); the rest
  # (navigation, media keys) is untitled, as in niri's
  show = key: title: command: { inherit key title command; };
  sections =
  [
    {
      name = "Apps and shell";
      binds =
      [
        (show (Mod "Return") "Terminal" (exec wezterm))
        (show (Mod "space") "Launcher" (exec walker))
        (show (Mod "v") "Clipboard history" (exec "${walker} -m clipboard"))
        (show (Mod "a") "Control center" (exec (ipc "panels" "toggle" [ "control" ])))
        (show (Mod "d") "Dashboard" (exec (ipc "panels" "toggle" [ "dashboard" ])))
        (show (Mod "n") "Notification center" (exec (ipc "notifications" "toggle" [ ])))
        (show (ModShift "n") "Toggle do not disturb" (exec (ipc "notifications" "toggleDnd" [ ])))
        (show (ModShift "r") "Screen recorder" (exec (ipc "recorder" "toggle" [ ])))
        (show (Mod "w") "Wallpaper picker" (exec (lib.getExe pkgs.waypaper)))
        (show "Print" "Screenshot area" (exec "screenshot area"))
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
        # consume / expel: the next window opens stacked, or beside
        (show (Mod "bracketleft") "Split vertically" "splitv")
        (show (Mod "bracketright") "Split horizontally" "splith")
      ];
    }
  ];
  titled = lib.listToAttrs (
    map (b: lib.nameValuePair b.key b.command) (lib.concatMap (s: s.binds) sections)
  );

  # Mod(+Shift)+1..9: focus / move to workspace
  workspaces = lib.listToAttrs (
    lib.concatMap
      (i:
      let
        n = toString i;
      in
      [
        {
          name = Mod n;
          value = "workspace number ${n}";
        }
        {
          name = ModShift n;
          value = moveTo "number ${n}";
        }
      ])
      (lib.range 1 9)
  );
in
{
  # read by the quickshell hotkey overlay
  lib.haku.swayHotkeys = map
    (s:
    {
      inherit (s) name;
      binds = map (b: { inherit (b) key title; }) s.binds;
    })
    sections;

  wayland.windowManager.sway.config =
  {
    modifier = mod;
    terminal = wezterm;
    menu = walker;
    floating.modifier = mod;

    # Mod+R: no preset widths, so a resize mode instead
    modes.resize =
    {
      "h" = "resize shrink width 10 ppt";
      "l" = "resize grow width 10 ppt";
      "k" = "resize shrink height 10 ppt";
      "j" = "resize grow height 10 ppt";
      "Return" = "mode default";
      "Escape" = "mode default";
      ${Mod "r"} = "mode default";
    };

    keybindings = workspaces // titled //
    {
      # same as Print, so untitled
      ${ModShift "s"} = exec "screenshot area";
      # other variants of Mod+Minus / Mod+Equal
      ${ModShift "equal"} = "resize grow width 10 ppt";
      ${Mod "KP_Subtract"} = "resize shrink width 10 ppt";
      ${Mod "KP_Add"} = "resize grow width 10 ppt";

      # --- navigation -----------------------------------------------------
      ${Mod "h"} = "focus left";
      ${Mod "l"} = "focus right";
      ${Mod "k"} = "focus up";
      ${Mod "j"} = "focus down";

      ${Mod "u"} = "workspace next_on_output";
      ${Mod "i"} = "workspace prev_on_output";

      ${ModShift "h"} = "move left";
      ${ModShift "l"} = "move right";
      ${ModShift "k"} = "move up";
      ${ModShift "j"} = "move down";

      # workspaces can't be reordered; send this one to the next output
      ${ModShift "u"} = "move workspace to output right";
      ${ModShift "i"} = "move workspace to output left";

      ${ModCtrl "h"} = "focus output left";
      ${ModCtrl "l"} = "focus output right";

      ${ModCtrl "u"} = moveTo "next_on_output";
      ${ModCtrl "i"} = moveTo "prev_on_output";

      # --- media keys -----------------------------------------------------
      ${media "XF86AudioRaiseVolume"} = exec "${wpctl} set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+";
      ${media "XF86AudioLowerVolume"} = exec "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      ${media "XF86AudioMute"} = exec "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
      ${media "XF86AudioMicMute"} = exec "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
      ${media "XF86MonBrightnessUp"} = exec "${brightnessctl} set 5%+";
      ${media "XF86MonBrightnessDown"} = exec "${brightnessctl} set 5%-";
    };
  };
}
