# Palette-built wallpaper with a tinted NixOS logo.
{
  config,
  pkgs,
  ...
}:

let
  c = config.lib.stylix.colors.withHashtag;
  # recoloured by Stylix
  snowflake = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";
in
pkgs.runCommand "stylix-wallpaper.png"
{
  nativeBuildInputs = [ pkgs.imagemagick ];
}
''
  magick -size 3840x2160 radial-gradient:'${c.base01}'-'${c.base00}' \
    \( -background none -density 600 ${snowflake} -resize 1500x1500 \
       -fill '${c.base0E}' -colorize 100 -channel A -evaluate multiply 0.07 +channel \) \
    -gravity center -composite \
    "png24:$out"
''
