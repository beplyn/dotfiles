# Shared look for the shell layer (waybar, swaync, walker).
# Every color comes from Stylix, exported as GTK named colors so each
# stylesheet can use @accent / alpha(@base, 0.8) instead of raw hex.
{ config }:

let
  c = config.lib.stylix.colors.withHashtag;
  fonts = config.stylix.fonts;
in
{
  radius = 12;
  glass = 0.82;

  font = ''"${fonts.monospace.name}", "Maple Mono NF", "Symbols Nerd Font"'';
  fontSize = fonts.sizes.desktop;
  popupFontSize = fonts.sizes.popups;

  css = ''
    @define-color base     ${c.base00};
    @define-color mantle   ${c.base01};
    @define-color surface  ${c.base02};
    @define-color overlay  ${c.base03};
    @define-color subtext  ${c.base04};
    @define-color text     ${c.base05};
    @define-color bright   ${c.base06};
    @define-color red      ${c.base08};
    @define-color orange   ${c.base09};
    @define-color yellow   ${c.base0A};
    @define-color green    ${c.base0B};
    @define-color cyan     ${c.base0C};
    @define-color blue     ${c.base0D};
    @define-color accent   ${c.base0E};
  '';
}
