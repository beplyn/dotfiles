# Shell look, palette colours as GTK named colours.
{ config, lib, ... }:

let
  fonts = config.stylix.fonts;
  readOnly =
    type: description:
    lib.mkOption
    {
      inherit type description;
      readOnly = true;
    };
in
{
  options.themes.shell =
  {
    radius = readOnly lib.types.int "Corner radius of shell surfaces, in pixels.";
    glass = readOnly lib.types.float "Panel and bar opacity; niri blurs what shows through.";
    font = readOnly lib.types.str "CSS font-family list for shell surfaces.";
    fontSize = readOnly lib.types.number "Font size of bars and panels, in points.";
    popupFontSize = readOnly lib.types.number "Font size of popups and launchers, in points.";
    css = readOnly lib.types.lines "GTK @define-color block of the palette.";
  };

  config.themes.shell =
  {
    radius = 12;
    glass = config.stylix.opacity.desktop;

    font = ''"${fonts.monospace.name}", monospace'';
    fontSize = fonts.sizes.desktop;
    popupFontSize = fonts.sizes.popups;

    # one @define-color per palette name
    css = lib.concatLines (lib.mapAttrsToList (n: v: "@define-color ${n} ${v};") config.themes.palette);
  };
}
