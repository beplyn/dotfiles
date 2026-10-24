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
  swaync-client = lib.getExe' config.services.swaync.package "swaync-client";
  swaylock = lib.getExe config.programs.swaylock.package;
  wpctl = lib.getExe' pkgs.wireplumber "wpctl";
  brightnessctl = lib.getExe pkgs.brightnessctl;

  # Media keys keep working on the lock screen.
  media = args: {
    action.spawn = args;
    allow-when-locked = true;
  };

  # Mod+1..9 focuses a workspace, Mod+Shift+1..9 sends the column there.
  workspaces = lib.listToAttrs (
    lib.concatMap (i: [
      {
        name = Mod (toString i);
        value.action.focus-workspace = i;
      }
      {
        name = ModShift (toString i);
        value.action.move-column-to-workspace = i;
      }
    ]) (lib.range 1 9)
  );
in
{
  programs.niri.settings.binds = workspaces // {
    ${Mod "Return"} = {
      action.spawn = [ kitty ];
      hotkey-overlay = {
        title = "Kitty";
      };
    };
    ${Mod "Space"} = {
      action.spawn = [ walker ];
      hotkey-overlay = {
        title = "Launcher";
      };
    };
    ${Mod "V"} = {
      action.spawn = [
        walker
        "-m"
        "clipboard"
      ];
      hotkey-overlay = {
        title = "Clipboard history";
      };
    };
    ${Mod "N"} = {
      action.spawn = [
        swaync-client
        "-t"
        "-sw"
      ];
      hotkey-overlay = {
        title = "Notification center";
      };
    };
    "Print" = {
      action.spawn = [
        "screenshot"
        "area"
      ];
      hotkey-overlay = {
        title = "Screenshot area";
      };
    };
    ${ModShift "S"}.action.spawn = [
      "screenshot"
      "area"
    ];
    "Shift+Print" = {
      action.spawn = [
        "screenshot"
        "output"
      ];
      hotkey-overlay = {
        title = "Screenshot screen";
      };
    };

    ${Mod "Q"} = {
      action.close-window = [ ];
      repeat = false;
    };
    ${ModShift "E"}.action.quit = [ ];
    "Mod+Alt+L" = {
      action.spawn = [
        swaylock
        "-f"
      ];
      hotkey-overlay = {
        title = "Lock screen";
      };
    };
    ${ModShift "Slash"}.action.show-hotkey-overlay = [ ];
    ${Mod "Tab"} = {
      action.toggle-overview = [ ];
      repeat = false;
    };

    ${Mod "F"}.action.fullscreen-window = [ ];
    ${ModShift "F"}.action.maximize-column = [ ];
    "Mod+Alt+X".action.toggle-window-floating = [ ];
    ${Mod "R"}.action.switch-preset-column-width = [ ];
    ${Mod "Minus"}.action.set-column-width = "-10%";
    ${Mod "Plus"}.action.set-column-width = "+10%";
    ${ModShift "Equal"}.action.set-column-width = "+10%";

    ${Mod "H"}.action.focus-column-left = [ ];
    ${Mod "L"}.action.focus-column-right = [ ];
    ${Mod "K"}.action.focus-window-or-workspace-up = [ ];
    ${Mod "J"}.action.focus-window-or-workspace-down = [ ];

    ${Mod "BracketLeft"}.action.consume-or-expel-window-left = [ ];
    ${Mod "BracketRight"}.action.consume-or-expel-window-right = [ ];

    ${Mod "U"}.action.focus-workspace-down = [ ];
    ${Mod "I"}.action.focus-workspace-up = [ ];

    ${ModShift "H"}.action.move-column-left = [ ];
    ${ModShift "L"}.action.move-column-right = [ ];
    ${ModShift "K"}.action.move-window-up = [ ];
    ${ModShift "J"}.action.move-window-down = [ ];

    ${ModShift "U"}.action.move-workspace-down = [ ];
    ${ModShift "I"}.action.move-workspace-up = [ ];

    ${ModCtrl "H"}.action.focus-monitor-left = [ ];
    ${ModCtrl "L"}.action.focus-monitor-right = [ ];

    ${ModCtrl "U"}.action.move-column-to-workspace-down = [ ];
    ${ModCtrl "I"}.action.move-column-to-workspace-up = [ ];

    "XF86AudioRaiseVolume" = media [
      wpctl
      "set-volume"
      "-l"
      "1.0"
      "@DEFAULT_AUDIO_SINK@"
      "5%+"
    ];
    "XF86AudioLowerVolume" = media [
      wpctl
      "set-volume"
      "@DEFAULT_AUDIO_SINK@"
      "5%-"
    ];
    "XF86AudioMute" = media [
      wpctl
      "set-mute"
      "@DEFAULT_AUDIO_SINK@"
      "toggle"
    ];
    "XF86AudioMicMute" = media [
      wpctl
      "set-mute"
      "@DEFAULT_AUDIO_SOURCE@"
      "toggle"
    ];
    "XF86MonBrightnessUp" = media [
      brightnessctl
      "set"
      "5%+"
    ];
    "XF86MonBrightnessDown" = media [
      brightnessctl
      "set"
      "5%-"
    ];
  };
}
