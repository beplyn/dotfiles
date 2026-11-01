{
  config,
  ...
}:

let
  p = config.themes.palette;
in
{
  programs.niri.settings =
  {
    layout =
    {
      gaps = 3;

      preset-column-widths =
      [
        { proportion = 1.0 / 3.0; }
        { proportion = 1.0 / 2.0; }
        { proportion = 2.0 / 3.0; }
      ];
      default-column-width.proportion = 0.5;
      center-focused-column = "never";

      # active border: accent
      border =
      {
        enable = true;
        width = 2;
        active = { color = p.accent; };
        urgent = { color = p.red; };
      };
      focus-ring.enable = false;

      shadow =
      {
        enable = true;
        color = "${p.background}80";
        inactive-color = "${p.background}50";
        draw-behind-window = false;
        offset =
        {
          x = 0;
          y = 4;
        };
        softness = 30;
        spread = 4;
      };
      insert-hint =
      {
        enable = true;
        display = { color = "${p.accent}80"; };
      };
    };
    prefer-no-csd = true;

    overview =
    {
      workspace-shadow =
      {
        enable = true;
        color = "${p.background}80";
        offset =
        {
          x = 0;
          y = 4;
        };
        softness = 30;
        spread = 4;
      };
    };

    # shell-radius corners, hollow borders
    window-rules =
    [
      {
        geometry-corner-radius =
          let
            r = config.themes.shell.radius * 1.0;
          in
          {
            top-left = r;
            top-right = r;
            bottom-left = r;
            bottom-right = r;
          };
        clip-to-geometry = true;
        # CSD: stops the border tinting translucent windows
        draw-border-with-background = false;
      }
    ];
  };
}
