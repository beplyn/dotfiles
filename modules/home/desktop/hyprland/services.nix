{ config, ... }:

# the hypr daemons, on hyprland-session.target; hyprlock and hypridle are
# in shell/lock.nix
let
  target = "hyprland-session.target";
in
{
  # the shell's pick from ~/.cache/wallpapers (quickshell/wallpaper.nix),
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
          path = "${config.lib.haku.wallpaper.cache}/current.jpg";
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

  services.hyprpolkitagent.enable = true;
}
