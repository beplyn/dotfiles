{
  pkgs,
  lib,
  ...
}:
let
  Mod = k: "Mod+${k}";
  ModShift = k: "Mod+Shift+${k}";
  ModCtrl = k: "Mod+Ctrl+${k}";
  ModCtrlShift = k: "Mod+Ctrl+Shift+${k}";
in
{
  programs.niri.binds = {
    ${Mod "Return"} = {
      action.spawn = [ "kitty" ];
      hotkey-overlay = {
        title = "Kitty";
        hidden = false;
      };
    };
    ${Mod "Space"} = {
      action.spawn = [ "walker" ];
      hotkey-overlay = {
        title = "Launcher";
        hidden = false;
      };
    };
    ${Mod "Q"} = {
      action.close-window = [ ];
      repeat = false;
    };
    ${Mod "F"}.action.maximize-column = [ ];

    ${Mod "H"}.action.focus-column-left = [ ];
    ${Mod "L"}.action.focus-column-right = [ ];
    ${Mod "K"}.action.focus-column-up = [ ];
    ${Mod "J"}.action.focus-column-down = [ ];

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

  };
}
