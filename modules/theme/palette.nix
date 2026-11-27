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
    brightest = c.base07;
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
    primary = blue;
    secondary = purple;
    tertiary = cyan;
    error = red;
    success = green;
    warning = yellow;
  };

  # the scheme's colours without the neutrals, for things that take one each
  options.themes.accents = lib.mkOption
  {
    type = lib.types.listOf lib.types.str;
    readOnly = true;
    description = "The eight accent colours of the Stylix scheme, red to brown.";
  };

  config.themes.accents = map (n: c.${n})
    [ "base08" "base09" "base0A" "base0B" "base0C" "base0D" "base0E" "base0F" ];
}
