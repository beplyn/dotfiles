{ inputs, pkgs, ... }:

# niri-flake's module already sets up polkit, the GNOME portal and gnome-keyring.
{
  programs.niri = {
    enable = true;
    # niri-flake's default (niri-stable) no longer builds against nixpkgs.
    # niri-glass is niri 26.04 plus a liquid-glass background effect.
    package = inputs.niri-glass.packages.${pkgs.stdenv.hostPlatform.system}.niri-glass;
  };

  # niri spawns this on demand for X11 clients (Steam).
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # Run Electron/Chromium apps (Equibop) natively on Wayland.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # swaylock can't check passwords without its own PAM service.
  security.pam.services.swaylock = { };
}
