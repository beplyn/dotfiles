{
  config,
  lib,
  osConfig,
  ...
}:

# input, gaps, borders and rules mirrored from niri
let
  p = config.themes.palette;
  niri = config.programs.niri.settings;
  xkb = osConfig.services.xserver.xkb;
  toasts = ''class="^steam$" title="^notificationtoasts_\d+_desktop$"'';
in
{
  # awww draws the wallpaper
  stylix.targets.sway.useWallpaper = false;

  wayland.windowManager.sway =
  {
    enable = true;
    # the NixOS module installs sway and its session
    package = null;

    config =
    {
      # sway rejects an empty xkb_variant
      input."type:keyboard" =
      {
        xkb_layout = xkb.layout;
      }
      // lib.optionalAttrs (xkb.variant != "") { xkb_variant = xkb.variant; };
      focus.followMouse = "yes";

      gaps.inner = niri.layout.gaps;
      window =
      {
        border = niri.layout.border.width;
        titlebar = false;
        commands =
        [
          {
            criteria.app_id = "^equibop$";
            command = "opacity 0.75";
          }
          {
            criteria.class = "^steam$";
            command = "opacity 0.75";
          }
          {
            criteria.app_id = "^com.gabm.satty$";
            command = "floating enable";
          }
        ];
      };
      floating =
      {
        border = niri.layout.border.width;
        titlebar = false;
      };

      # active border: accent, as in niri
      colors.focused =
      {
        border = lib.mkForce p.accent;
        childBorder = lib.mkForce p.accent;
      };

      # waybar and quickshell run as systemd services
      bars = [ ];
    };

    # Steam toasts float without taking focus; sway can't anchor them top right
    extraConfig = ''
      for_window [${toasts}] floating enable
      no_focus [${toasts}]
    '';
  };

  # sway's exit stops sway-session.target but left graphical-session.target
  # up: waybar and co. crash-looped into start-limit-hit, and the next
  # session found the target active and never brought them back
  systemd.user.targets.sway-session.Unit.PropagatesStopTo = [ "graphical-session.target" ];
}
