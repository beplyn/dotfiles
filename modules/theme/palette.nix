{ config, lib, ... }:

let
  c = config.lib.stylix.colors.withHashtag;
in
{
  options.themes.palette = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    description = "Compatibility palette derived from Stylix.";
  };

  config.themes.palette = {
    background = c.base00;
    surface = c.base02;
    surfaceBright = c.base03;
    foreground = c.base05;
    red = c.base08;
    orange = c.base09;
    yellow = c.base0A;
    green = c.base0B;
    aqua = c.base0C;
    blue = c.base0D;
    purple = c.base0E;
    text = c.base05;
    muted = c.base03;
    accent = c.base0E;
    error = c.base08;
    success = c.base0B;
    warning = c.base0A;
  };
}
