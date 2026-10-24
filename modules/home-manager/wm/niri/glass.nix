{
  inputs,
  lib,
  options,
  ...
}:

# Liquid-glass background for kitty (needs the niri-glass package, see
# modules/nixos/system/niri.nix). niri-flake's settings schema has no
# background-effect yet, so the rule is appended to the rendered settings as
# raw KDL; niri validates the result at build time.
let
  inherit (inputs.niri.lib.kdl) node leaf;
in
{
  programs.niri.config = lib.mkForce (
    options.programs.niri.config.default
    ++ [
      (node "window-rule" [ ] [
        (leaf "match" { app-id = "^kitty$"; })
        (node "background-effect" [ ] [
          (leaf "blur" true)
          (leaf "xray" true)
          (node "liquid-glass" [ ] [
            (leaf "refraction-strength" 3.0)
            (leaf "power-factor" 10)
            (leaf "refraction-power" 1.0)
            (leaf "glow-weight" 0.0001)
            (leaf "edge-lighting" 0.2)
            (leaf "saturation" 0.9)
            (leaf "vibrancy" 0.2)
            (leaf "adaptive-dim" 0.25)
            (leaf "adaptive-boost" 0.25)
            (leaf "physical-refraction" 0)
            (leaf "lens-distortion" 0)
            (leaf "fringing" 0)
          ])
        ])
      ])
    ]
  );
}
