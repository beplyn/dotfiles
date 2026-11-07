{
  config,
  lib,
  osConfig,
  ...
}:

let
  niri = config.programs.niri.settings;
  xkb = osConfig.services.xserver.xkb;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    configType = "lua";
    systemd.enable = true;
    settings = {
      "$mod" = "SUPER";
      input = {
        kb_layout = xkb.layout;
        kb_variant = lib.mkIf (xkb.variant != "") xkb.variant;
        follow_mouse = 1;
      };
      general = {
        gaps_in = niri.layout.gaps;
        gaps_out = niri.layout.gaps;
        border_size = niri.layout.border.width;
        layout = "dwindle";
      };
      decoration = {
        rounding = config.themes.shell.radius;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        shadow.enabled = true;
        blur = {
          enabled = true;
          passes = 2;
          size = 4;
          new_optimizations = true;
        };
      };
      animations.enabled = true;
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
      };
      ecosystem = {
        no_update_news = true;
        no_donation_nag = true;
      };
    };
  };

  services.hyprpaper = {
    enable = true;
    settings.splash = false;
  };

  services.hyprpolkitagent.enable = true;

  # Do not start Hyprpaper in the other compositor sessions.
  systemd.user.services.hyprpaper.Unit.ConditionEnvironment =
    lib.mkForce "HYPRLAND_INSTANCE_SIGNATURE";
}
