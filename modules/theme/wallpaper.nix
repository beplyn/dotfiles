# The Stylix wallpaper: a soft radial glow from the palette with a faint,
# palette-tinted NixOS snowflake. Built from the colours rather than shipped
# as a file, so every theme gets a matching one. The greeter and the lock
# screen show it; the session's own wallpaper is still picked with waypaper.
{
  config,
  pkgs,
  ...
}:

let
  c = config.lib.stylix.colors.withHashtag;
  # Recoloured by the Stylix nixos-icons overlay.
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
