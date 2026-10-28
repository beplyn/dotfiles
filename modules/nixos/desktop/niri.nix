{ inputs, pkgs, ... }:

# niri-flake's module already sets up polkit, the GNOME portal and gnome-keyring.
{
  programs.niri = {
    enable = true;
    # niri-flake's default (niri-stable) no longer builds against nixpkgs.
    # niri-glass is niri 26.04 plus a liquid-glass background effect. Its
    # libdisplay-info-sys crate needs < 0.4, so swap in 0.3 like nixpkgs' niri.
    package =
      inputs.niri-glass.packages.${pkgs.stdenv.hostPlatform.system}.niri-glass.overrideAttrs
        (old: {
          buildInputs = map (
            p: if (p.pname or "") == "libdisplay-info" then pkgs.libdisplay-info_0_3 else p
          ) old.buildInputs;
          # Drop the overlay's leftover debug logging; the non-xray one fires
          # every frame for every glass window.
          postPatch = old.postPatch + ''
            sed -i '/warn!("LIQUID GLASS:/d' src/render_helpers/background_effect.rs
            if grep -q 'LIQUID GLASS:' src/render_helpers/background_effect.rs; then exit 1; fi
          '';
        });
  };

  # niri spawns this on demand for X11 clients (Steam).
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # Run Electron/Chromium apps (Equibop) natively on Wayland.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # swaylock can't check passwords without its own PAM service.
  security.pam.services.swaylock = { };
}
