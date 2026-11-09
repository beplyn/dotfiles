{ pkgs, ... }:

# polkit, portal and keyring come from niri-flake
{
  programs.niri =
  {
    enable = true;
    # nixpkgs' build, from the binary cache; niri-flake's still wants
    # libdisplay-info 0.2
    package = pkgs.niri;
  };

  # X11 for Steam
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # Electron on Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # hyprlock PAM service
  security.pam.services.hyprlock = { };
}
