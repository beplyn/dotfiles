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

    keybindings = workspaces //
    {
      # --- apps and shell -------------------------------------------------
      ${Mod "Return"} = exec wezterm;
      ${Mod "space"} = exec walker;
      ${Mod "v"} = exec "${walker} -m clipboard";
      ${Mod "a"} = exec (ipc "panels" "toggle" [ "control" ]);
      ${Mod "d"} = exec (ipc "panels" "toggle" [ "dashboard" ]);
      ${Mod "n"} = exec (ipc "notifications" "toggle" [ ]);
      ${ModShift "n"} = exec (ipc "notifications" "toggleDnd" [ ]);
      ${ModShift "r"} = exec (ipc "recorder" "toggle" [ ]);
      ${Mod "w"} = exec (lib.getExe pkgs.waypaper);
      "Print" = exec "screenshot area";
      ${ModShift "s"} = exec "screenshot area";
      "Shift+Print" = exec "screenshot output";

      # --- session --------------------------------------------------------
      ${Mod "q"} = "kill";
      # niri asks before quitting too
      ${ModShift "e"} = exec "swaynag -t warning -m 'Quit sway?' -B 'Quit' 'swaymsg exit'";
      ${ModAlt "l"} = exec "${loginctl} lock-session";
      ${Mod "x"} = exec (ipc "panels" "toggle" [ "power" ]);
      # no overview; jump to the previous workspace
      ${Mod "Tab"} = "workspace back_and_forth";

      # --- window sizing --------------------------------------------------
      # no maximize-column; tabbed fills the workspace and keeps the bar
      ${Mod "f"} = "layout toggle tabbed split";
      ${ModShift "f"} = "fullscreen toggle";
      ${ModAlt "x"} = "floating toggle";
      ${Mod "r"} = "mode resize";
      ${Mod "minus"} = "resize shrink width 10 ppt";
      ${Mod "equal"} = "resize grow width 10 ppt";
      ${ModShift "equal"} = "resize grow width 10 ppt";
      ${Mod "KP_Subtract"} = "resize shrink width 10 ppt";
      ${Mod "KP_Add"} = "resize grow width 10 ppt";

      # consume / expel: the next window opens stacked, or beside
      ${Mod "bracketleft"} = "splitv";
      ${Mod "bracketright"} = "splith";

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
