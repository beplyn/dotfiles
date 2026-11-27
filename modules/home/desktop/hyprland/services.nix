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

  # the daemon only; the sunset schedule and warmth come from the shell's
  # services/NightLight.qml, so no profiles here to fight it
  services.hyprsunset =
  {
    enable = true;
    systemdTarget = target;
  };

  services.hyprpolkitagent.enable = true;

  # Mod+Alt+Space; the daemon keeps it warm, `hyprlauncher` opens it
  services.hyprlauncher.enable = true;
}
