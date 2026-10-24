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
      gaps = 4;
      background-color = c.base00;
      border = {
        enable = true;
        width = 2;

        active = { color = c.base0E; };
        inactive = { color = c.base03; };
        urgent = { color = c.base08; };
      };
      focus-ring = {
        enable = true;
        width = 2;
        active = { color = c.base0E; };
        inactive = { color = c.base03; };
        urgent = { color = c.base08; };
      };
      shadow = {
        enable = true;
        color = "${c.base00}80";
        draw-behind-window = true;
        inactive-color = "${c.base00}50";
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
      default-column-width.proportion = 0.5;
      center-focused-column = "never";
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
  };
}
