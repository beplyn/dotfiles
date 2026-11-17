{ lib, pkgs, ... }:

# the desktop; config lives in home-manager (desktop/hyprland). The module
# brings the portal (xdph), polkit and the session file.
{
  programs.hyprland =
  {
    enable = true;
    xwayland.enable = true;
  };

  # hide hyprland-uwsm.desktop, hm runs the session
  environment.sessionVariables.XDG_DATA_DIRS = lib.mkBefore
  [
    "${pkgs.writeTextDir "share/wayland-sessions/hyprland-uwsm.desktop" ''
      [Desktop Entry]
      Name=Hyprland (uwsm-managed)
      Type=Application
      Hidden=true
    ''}/share"
  ];

  # other hypr tools; the daemons run from home-manager
  environment.systemPackages =
  [
    pkgs.hyprpicker
    pkgs.hyprsysteminfo
    pkgs.hyprpwcenter
    pkgs.hyprshutdown
  ];

  # portal only: no DCC, or Chromium screen shares fail on radeonsi
  systemd.user.services.xdg-desktop-portal-hyprland.environment.AMD_DEBUG = "nodcc";

  # Electron on Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # hyprlock's PAM service
  security.pam.services.hyprlock = { };
}
