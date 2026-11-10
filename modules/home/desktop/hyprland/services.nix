{
  config,
  lib,
  ...
}:

# the hypr daemons, on hyprland-session.target only so the other sessions
# keep theirs; hyprlock and hypridle are shared (shell/lock.nix)
let
  target = "hyprland-session.target";
in
{
  # wallpaper-pick's and waypaper's image (quickshell/wallpaper.nix),
  # not Stylix's
  stylix.targets.hyprland.hyprpaper.enable = false;
  stylix.targets.hyprpaper.enable = false;
  services.hyprpaper =
  {
    enable = true;
    systemdTarget = target;
    settings =
    {
      splash = false;
      wallpaper =
      [
        {
          monitor = "";
          path = "${config.xdg.cacheHome}/wallpaper/current.png";
          fit_mode = "cover";
        }
      ];
    };
  };

  # warm at night; Mod+Alt+N and the shell's night light toggle it by hand.
  # Mornings go to 6000 K, not identity, which leaves `hyprctl hyprsunset
  # temperature` reporting the evening value
  services.hyprsunset =
  {
    enable = true;
    systemdTarget = target;
    settings.profile =
    [
      {
        time = "7:00";
        temperature = 6000;
      }
      {
        time = "21:00";
        temperature = 4000;
      }
    ];
  };

  # niri brings its own agent
  services.hyprpolkitagent.enable = true;
  systemd.user.services.hyprpolkitagent =
  {
    Unit =
    {
      PartOf = lib.mkForce [ target ];
      After = lib.mkForce [ target ];
    };
    Install.WantedBy = lib.mkForce [ target ];
  };
}
