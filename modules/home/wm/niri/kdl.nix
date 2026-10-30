{
  config,
  inputs,
  lib,
  options,
  ...
}:

# Raw KDL for what niri-flake's schema lacks: blur, shadows, nirimation.
let
  inherit (inputs.niri.lib.kdl) node leaf;
  radius = config.themes.shell.radius * 1.0;
in
{
  programs.niri.config = lib.mkForce (
    options.programs.niri.config.default
    ++
    [
      # global blur strength, softened (defaults 3/3)
      (node "blur" [ ]
      [
        (leaf "passes" 2)
        (leaf "offset" 2.0)
      ])
      (node "window-rule" [ ]
      [
        (leaf "match" { app-id = "^kitty$"; })
        (node "background-effect" [ ]
        [
          # no xray: blur what's behind; saturation 0 keeps it grey
          (leaf "blur" true)
          (leaf "xray" false)
          (leaf "saturation" 0.0)
        ])
      ])
      # blur translucent windows
      (node "window-rule" [ ]
      [
        (leaf "match" { app-id = "^equibop$"; })
        (leaf "match" { app-id = "^steam$"; })
        (node "background-effect" [ ]
        [
          (leaf "blur" true)
          (leaf "xray" false)
        ])
      ])
      # waybar capsule: round, shadow, blur
      (node "layer-rule" [ ]
      [
        (leaf "match" { namespace = "^waybar$"; })
        (leaf "geometry-corner-radius" radius)
        (node "shadow" [ ] [ (leaf "on" [ ]) ])
        (node "background-effect" [ ]
        [
          (leaf "blur" true)
          (leaf "xray" false)
        ])
        (node "popups" [ ]
        [
          (leaf "geometry-corner-radius" radius)
          (node "background-effect" [ ] [ (leaf "blur" true) ])
        ])
      ])
      # quickshell requests its own blur; no xray
      (node "layer-rule" [ ]
      [
        (leaf "match" { namespace = "^haku-"; })
        (node "background-effect" [ ] [ (leaf "xray" false) ])
      ])
    ]
    ++ lib.optional (config.programs.nirimation.kdl != null) (
      leaf "include" [ "${config.programs.nirimation.kdl}" ]
    )
  );
}
