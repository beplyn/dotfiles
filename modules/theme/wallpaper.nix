# Palette-built wallpaper with a tinted NixOS logo.
{
  config,
  pkgs,
  ...
}:

let
  p = config.themes.palette;
  # white, so the accent tint below takes cleanly
  snowflake = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";
in
pkgs.runCommand "stylix-wallpaper.png"
{
  nativeBuildInputs = [ pkgs.imagemagick ];
}
''
  magick -size 3840x2160 radial-gradient:'${p.mantle}'-'${p.background}' \
    \( -background none -density 600 ${snowflake} -resize 1500x1500 \
       -fill '${p.accent}' -colorize 100 -channel A -evaluate multiply 0.07 +channel \) \
    -gravity center -composite \
    "png24:$out"
''
