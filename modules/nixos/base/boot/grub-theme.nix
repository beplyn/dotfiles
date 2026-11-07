# Palette-built GRUB theme: panel menu, OS icons, countdown bar.
{
  config,
  pkgs,
  subst,
  ...
}:

let
  vars = config.themes.palette //
  {
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
