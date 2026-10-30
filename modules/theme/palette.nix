# The one colour vocabulary; modules use these names, not raw baseXX.
{ config, lib, ... }:

let
  c = config.lib.stylix.colors.withHashtag;
in
{
  options.themes.palette = lib.mkOption
  {
    type = lib.types.attrs;
    readOnly = true;
    description = "Named colours derived from the Stylix base16 scheme.";
  };

  config.themes.palette = rec
  {
    background = c.base00;
    mantle = c.base01;
    surface = c.base02;
    muted = c.base03;
    subtext = c.base04;
    foreground = c.base05;
    bright = c.base06;
    red = c.base08;
    orange = c.base09;
    yellow = c.base0A;
    green = c.base0B;
    cyan = c.base0C;
    blue = c.base0D;
    purple = c.base0E;
    brown = c.base0F;

    # semantic aliases
    accent = purple;
    error = red;
    success = green;
    warning = yellow;
  };
}
