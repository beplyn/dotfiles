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
# - Blur behind kitty and the other translucent windows (needs the niri-glass
#   package, see modules/nixos/system/niri.nix). No liquid-glass on kitty: its
#   shader ignored the terminal's alpha and left an opaque tinted surface.
# - Blur and shadow for the waybar capsule and the Quickshell panels.
# - The nirimation animations block, included by store path so validation
#   sees it.
let
  inherit (inputs.niri.lib.kdl) node leaf;
  radius = config.themes.shell.radius * 1.0;
in
{
  programs.niri.config = lib.mkForce (
    options.programs.niri.config.default
    ++ [
      # Blur strength is global in niri (rules can't set it per window), so
      # this softens it everywhere; mainly so kitty's frost is lighter.
      # Defaults are passes 3 / offset 3.
      (node "blur" [ ] [
        (leaf "passes" 2)
        (leaf "offset" 2.0)
      ])
      (node "window-rule" [ ] [
        (leaf "match" { app-id = "^kitty$"; })
        (node "background-effect" [ ] [
          # Frosted glass over whatever is actually behind the window. xray
          # would instead sample the wallpaper at the window's position, so
          # windows over different parts of it pick up different tints.
          # Saturation 0 (default 1.5) keeps the frost neutral grey instead of
          # amplifying the colours behind it into a purple cast.
          (leaf "blur" true)
          (leaf "xray" false)
          (leaf "saturation" 0.0)
        ])
      ])
      # Blur behind the windows rules.nix makes translucent.
      (node "window-rule" [ ] [
        (leaf "match" { app-id = "^equibop$"; })
        (leaf "match" { app-id = "^steam$"; })
        (node "background-effect" [ ] [
          (leaf "blur" true)
          (leaf "xray" false)
        ])
      ])
      # Waybar's surface is exactly its capsule, so round, shadow and blur
      # it like a window. Its tray menus get the same frosted look.
      (node "layer-rule" [ ] [
        (leaf "match" { namespace = "^waybar$"; })
        (leaf "geometry-corner-radius" radius)
        (node "shadow" [ ] [ (leaf "on" [ ]) ])
        (node "background-effect" [ ] [
          (leaf "blur" true)
          (leaf "xray" false)
        ])
        (node "popups" [ ] [
          (leaf "geometry-corner-radius" radius)
          (node "background-effect" [ ] [ (leaf "blur" true) ])
        ])
      ])
      # Quickshell panels request a card-shaped blur themselves through
      # ext-background-effect; xray off makes it frost the windows below
      # instead of showing the wallpaper.
      (node "layer-rule" [ ] [
        (leaf "match" { namespace = "^haku-"; })
        (node "background-effect" [ ] [ (leaf "xray" false) ])
      ])
    ]
    ++ lib.optional (config.programs.nirimation.kdl != null) (
      leaf "include" [ "${config.programs.nirimation.kdl}" ]
    )
  );
}
