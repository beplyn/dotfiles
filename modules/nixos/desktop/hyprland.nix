{ pkgs, ... }:

# fourth session next to niri, sway and mango; config lives in home-manager
# (desktop/hyprland). The module brings the portal (xdph) and the session file.
{
  programs.hyprland =
  {
    enable = true;
    xwayland.enable = true;
  };

  # the rest of the hypr ecosystem the session binds to; hyprlock, hypridle,
  # hyprpaper, hyprsunset and hyprpolkitagent run from home-manager
  environment.systemPackages =
  [
    pkgs.hyprpicker
    pkgs.hyprsysteminfo
    pkgs.hyprpwcenter
    pkgs.hyprshutdown
    pkgs.hyprland-qtutils
  ];
}
