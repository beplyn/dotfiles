{ inputs, pkgs, ... }:

# polkit, portal and keyring come from niri-flake
{
  programs.niri =
  {
    enable = true;
    # niri-glass; libdisplay-info-sys needs 0.3
    package =
      inputs.niri-glass.packages.${pkgs.stdenv.hostPlatform.system}.niri-glass.overrideAttrs
        (old:
        {
          buildInputs = map (
            p: if (p.pname or "") == "libdisplay-info" then pkgs.libdisplay-info_0_3 else p
          ) old.buildInputs;
          # drop per-frame debug logging
          postPatch = old.postPatch + ''
            sed -i '/warn!("LIQUID GLASS:/d' src/render_helpers/background_effect.rs
            if grep -q 'LIQUID GLASS:' src/render_helpers/background_effect.rs; then exit 1; fi
          '';
        });
  };

  # X11 for Steam
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # Electron on Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # hyprlock PAM service
  security.pam.services.hyprlock = { };
}
