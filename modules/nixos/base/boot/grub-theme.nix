# Palette-built GRUB theme: panel menu, OS icons, countdown bar.
{
  config,
  lib,
  pkgs,
  subst,
  screen,
  ...
}:

let
  # drawn for 1080p; @pxN@ is N scaled to the boot screen's height
  px = lib.listToAttrs (map (n:
  {
    name = "px${toString n}";
    value = toString (n * screen.height / 1080);
  })
  [ 3 4 6 8 10 12 16 17 20 22 24 28 30 36 40 44 48 56 60 64 96 160 760 900 1000 1020 ]);

  vars = config.themes.palette // px //
  {
    inherit (screen) width height;
    host = config.networking.hostName;
    fontDir = config.stylix.fonts.monospace.package;
    snowflake = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
  };

  themeTxt = pkgs.writeText "theme.txt" (subst vars (builtins.readFile ./grub-theme.txt));
in
pkgs.runCommand "grub-theme"
{
  nativeBuildInputs = [ pkgs.imagemagick pkgs.grub2 ];
}
  (subst (vars // { inherit themeTxt; }) (builtins.readFile ./grub-theme.sh))
