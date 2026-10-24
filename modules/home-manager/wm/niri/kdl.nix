{
  config,
  inputs,
  lib,
  options,
  ...
}:

# Raw KDL appended to the rendered niri-flake settings, for things its schema
# doesn't cover. niri validates the result at build time.
#
# - Liquid-glass background for kitty (needs the niri-glass package, see
#   modules/nixos/system/niri.nix).
# - The nirimation animations block, included by store path so validation
#   sees it.
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
    ++ lib.optional (config.programs.nirimation.kdl != null) (
      leaf "include" [ "${config.programs.nirimation.kdl}" ]
    )
  );
}
