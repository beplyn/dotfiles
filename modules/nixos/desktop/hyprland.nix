{ pkgs, ... }:

# Hyprland's system-level session, portal and PAM integration.
{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.systemPackages = [
    pkgs.hyprpicker
    pkgs.hyprprop
    pkgs.hyprshot
  ];

  security.pam.services.hyprlock = { };
}
