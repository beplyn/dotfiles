{ lib, pkgs, ... }:

# the desktop; config lives in home-manager (desktop/hyprland). The module
# brings the portal (xdph), polkit and the session file.
{
  programs.hyprland =
  {
    enable = true;
    xwayland.enable = true;
  };

  # the package also ships hyprland-uwsm.desktop; hm's systemd integration
  # runs the session, so hide that entry. Earlier dirs win and ReGreet skips
  # Hidden ones
  environment.sessionVariables.XDG_DATA_DIRS = lib.mkBefore
  [
    "${pkgs.writeTextDir "share/wayland-sessions/hyprland-uwsm.desktop" ''
      [Desktop Entry]
      Name=Hyprland (uwsm-managed)
      Type=Application
      Hidden=true
    ''}/share"
  ];

  # the rest of the hypr ecosystem the session binds to; hyprlock, hypridle,
  # hyprpaper, hyprsunset and hyprpolkitagent run from home-manager
  environment.systemPackages =
  [
    pkgs.hyprpicker
    pkgs.hyprsysteminfo
    pkgs.hyprpwcenter
    pkgs.hyprshutdown
  ];

  # radeonsi's compressed (DCC) modifiers can't be fixated for Chromium's
  # screen share streams, which xdph then drops; plain ones work. Only for the
  # portal, the desktop keeps DCC
  systemd.user.services.xdg-desktop-portal-hyprland.environment.AMD_DEBUG = "nodcc";

  # Electron on Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # hyprlock's PAM service
  security.pam.services.hyprlock = { };
}
