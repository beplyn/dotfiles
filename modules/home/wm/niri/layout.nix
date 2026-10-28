{
  config,
  ...
}:

let
  c = config.lib.stylix.colors.withHashtag;
in
{
  programs.niri.settings = {
    layout = {
      gaps = 3;

      preset-column-widths = [
        { proportion = 1.0 / 3.0; }
        { proportion = 1.0 / 2.0; }
        { proportion = 2.0 / 3.0; }
      ];
      default-column-width.proportion = 0.5;
      center-focused-column = "never";

      # Stylix colors the border; active is pulled to base0E to match the
      # quickshell/walker accent.
      border = {
        enable = true;
        width = 2;
        active = { color = c.base0E; };
        urgent = { color = c.base08; };
      };
      focus-ring.enable = false;

      shadow = {
        enable = true;
        color = "${c.base00}80";
        inactive-color = "${c.base00}50";
        draw-behind-window = false;
        offset = {
          x = 0;
          y = 4;
        };
        softness = 30;
        spread = 4;
      };
      insert-hint = {
        enable = true;
        display = { color = "${c.base0E}80"; };
      };
    };
    prefer-no-csd = true;

    overview = {
      workspace-shadow = {
        enable = true;
        color = "${c.base00}80";
        offset = {
          x = 0;
          y = 4;
        };
        softness = 30;
        spread = 4;
      };
    };

    # 12px corners to match quickshell and walker, with hollow borders.
    window-rules = [
      {
        geometry-corner-radius =
          let
            r = 12.0;
          in
          {
            top-left = r;
            top-right = r;
            bottom-left = r;
            bottom-right = r;
          };
        clip-to-geometry = true;
        # Without CSD niri fills the border's colour behind the whole window,
        # which tints translucent windows (kitty) with the base0E accent.
        draw-border-with-background = false;
      }
    ];
  };
}
