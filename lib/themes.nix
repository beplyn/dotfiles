# Every colour scheme. Add or remove one here and the flake, rebuild and
# completions, Stylix, wallpapers, LEDs and Glance follow.
#
# scheme: base16-schemes file name, also the lutgen preset name
# folder: Papirus folder colour
# leds:   OpenRGB colours, dark enough to avoid washing out to white
# mocha:  forge icons use the Catppuccin Mocha flavour
# primary: hex replacing base0E (the palette's accent); unset keeps the scheme's
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

  # Mocha with another primary colour (base0E); the rest stays Mocha
  catppuccin-rosewater =
  {
    scheme = "catppuccin-mocha";
    folder = "palebrown";
    mocha = true;
    primary = "f5e0dc";
    leds = { main = "494342"; keyboard = "ab9c9a"; };
  };

  catppuccin-flamingo =
  {
    scheme = "catppuccin-mocha";
    folder = "pink";
    mocha = true;
    primary = "f2cdcd";
    leds = { main = "483d3d"; keyboard = "a98f8f"; };
  };

  catppuccin-pink =
  {
    scheme = "catppuccin-mocha";
    folder = "pink";
    mocha = true;
    primary = "f5c2e7";
    leds = { main = "493a45"; keyboard = "ab87a1"; };
  };

  catppuccin-red =
  {
    scheme = "catppuccin-mocha";
    folder = "red";
    mocha = true;
    primary = "f38ba8";
    leds = { main = "482932"; keyboard = "aa6175"; };
  };

  catppuccin-maroon =
  {
    scheme = "catppuccin-mocha";
    folder = "red";
    mocha = true;
    primary = "eba0ac";
    leds = { main = "463033"; keyboard = "a47078"; };
  };

  catppuccin-peach =
  {
    scheme = "catppuccin-mocha";
    folder = "orange";
    mocha = true;
    primary = "fab387";
    leds = { main = "4b3528"; keyboard = "af7d5e"; };
  };

  catppuccin-yellow =
  {
    scheme = "catppuccin-mocha";
    folder = "yellow";
    mocha = true;
    primary = "f9e2af";
    leds = { main = "4a4334"; keyboard = "ae9e7a"; };
  };

  catppuccin-green =
  {
    scheme = "catppuccin-mocha";
    folder = "green";
    mocha = true;
    primary = "a6e3a1";
    leds = { main = "314430"; keyboard = "749e70"; };
  };

  catppuccin-teal =
  {
    scheme = "catppuccin-mocha";
    folder = "teal";
    mocha = true;
    primary = "94e2d5";
    leds = { main = "2c433f"; keyboard = "679e95"; };
  };

  catppuccin-sky =
  {
    scheme = "catppuccin-mocha";
    folder = "cyan";
    mocha = true;
    primary = "89dceb";
    leds = { main = "294246"; keyboard = "5f9aa4"; };
  };

  catppuccin-sapphire =
  {
    scheme = "catppuccin-mocha";
    folder = "blue";
    mocha = true;
    primary = "74c7ec";
    leds = { main = "223b46"; keyboard = "518ba5"; };
  };

  catppuccin-blue =
  {
    scheme = "catppuccin-mocha";
    folder = "blue";
    mocha = true;
    primary = "89b4fa";
    leds = { main = "29364b"; keyboard = "5f7eaf"; };
  };

  catppuccin-lavender =
  {
    scheme = "catppuccin-mocha";
    folder = "indigo";
    mocha = true;
    primary = "b4befe";
    leds = { main = "36394c"; keyboard = "7e85b1"; };
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
