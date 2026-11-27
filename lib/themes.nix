# Every colour scheme. Add or remove one here and the flake, rebuild and
# completions, Stylix, wallpapers, LEDs and Glance follow.
#
# scheme: base16-schemes file name, also the lutgen preset name
# folder: Papirus folder colour
# leds:   OpenRGB colours, dark enough to avoid washing out to white
# mocha:  forge icons use the Catppuccin Mocha flavour
# contrast: optional Glance contrast-multiplier
{
  catppuccin =
  {
    scheme = "catppuccin-mocha";
    folder = "violet";
    mocha = true;
    contrast = "1.2";
    leds = { main = "1a0033"; keyboard = "8000ff"; };
  };

  gruvbox =
  {
    scheme = "gruvbox-dark-hard";
    folder = "pink";
    leds = { main = "b04a08"; keyboard = "b04a08"; };
  };

  gruvbox-soft =
  {
    scheme = "gruvbox-dark-soft";
    folder = "pink";
    leds = { main = "b04a08"; keyboard = "b04a08"; };
  };

  rose-pine =
  {
    scheme = "rose-pine";
    folder = "pink";
    leds = { main = "5c1a2e"; keyboard = "d4507a"; };
  };

  rose-pine-moon =
  {
    scheme = "rose-pine-moon";
    folder = "pink";
    leds = { main = "4d1e30"; keyboard = "c94c75"; };
  };

  nord =
  {
    scheme = "nord";
    folder = "nordic";
    leds = { main = "0a2a9c"; keyboard = "0a2a9c"; };
  };

  dracula =
  {
    scheme = "dracula";
    folder = "magenta";
    leds = { main = "2a1245"; keyboard = "9b5cf0"; };
  };

  tokyo-night =
  {
    scheme = "tokyo-night-dark";
    folder = "indigo";
    leds = { main = "1a1040"; keyboard = "3d5fd6"; };
  };

  everforest =
  {
    scheme = "everforest-dark-hard";
    folder = "green";
    leds = { main = "1f3318"; keyboard = "7fa04a"; };
  };

  kanagawa =
  {
    scheme = "kanagawa";
    folder = "blue";
    leds = { main = "0d1a3a"; keyboard = "3f6fd0"; };
  };

  onedark =
  {
    scheme = "onedark";
    folder = "blue";
    leds = { main = "0b2440"; keyboard = "3a8ee6"; };
  };

  solarized-dark =
  {
    scheme = "solarized-dark";
    folder = "teal";
    leds = { main = "04243a"; keyboard = "1f7cc0"; };
  };

  oxocarbon-dark =
  {
    scheme = "oxocarbon-dark";
    folder = "magenta";
    leds = { main = "3d0a1f"; keyboard = "d03d7a"; };
  };

  monokai =
  {
    scheme = "monokai";
    folder = "yellow";
    leds = { main = "1f2f0a"; keyboard = "8fd11a"; };
  };
}
