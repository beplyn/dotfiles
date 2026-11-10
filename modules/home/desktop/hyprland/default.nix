{
  lib,
  pkgs,
  ...
}:

# Hyprland's Lua config. The .nix files hand values to Lua as data modules
# (hypr/haku/data/*.lua); the .lua files next to them do the rest. Stylix
# adds its colours to the generated hyprland.lua.
let
  sessionWatch = pkgs.writeShellApplication
  {
    name = "session-watch";
    runtimeInputs = with pkgs;
    [
      bash
      coreutils
      gnugrep
      iproute2
      systemd
    ];
    text = builtins.readFile ./session-watch.sh;
  };
in
{
  imports =
  [
    ./binds.nix
    ./outputs.nix
    ./plugins.nix
    ./settings.nix
    ./toolkit.nix
    ./services.nix
  ];

  # value -> hypr/haku/data/<name>.lua, which `require("haku.data.<name>")` returns
  lib.haku.hyprlandData = name: value:
  {
    "haku/data/${name}" =
    {
      content = "return ${lib.generators.toLua { } value}\n";
      autoLoad = false;
    };
  };

  wayland.windowManager.hyprland =
  {
    enable = true;
    # the NixOS module's, with its portal
    package = null;
    portalPackage = null;
    configType = "lua";

    systemd =
    {
      enable = true;
      # a crashed session can leave graphical-session.target up with waybar
      # and co. failed, so start it afresh
      extraCommands =
      [
        "systemctl --user stop graphical-session.target"
        "systemctl --user reset-failed"
        "systemctl --user start hyprland-session.target"
        # the shutdown hook below misses a crash
        (lib.getExe sessionWatch)
      ];
    };

    extraLuaFiles =
    {
      "haku/look" = ./look.lua;
      "haku/rules" = ./rules.lua;
      "haku/binds" = ./binds.lua;
      "haku/session" = ./session.lua;
    };
  };

  # take the bar and co. down with Hyprland instead of leaving them to
  # crash-loop against a dead display
  systemd.user.targets.hyprland-session.Unit.PropagatesStopTo = [ "graphical-session.target" ];
}
