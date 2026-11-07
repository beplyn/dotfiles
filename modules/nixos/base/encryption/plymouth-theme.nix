# Palette-built Plymouth theme "palette": the LUKS prompt and boot splash.
{
  config,
  lib,
  pkgs,
  subst,
  fontFile,
  ...
}:

let
  p = config.themes.palette;

  # "#cba6f7" -> "0.796078, 0.65098, 0.968627" for Plymouth's colour arguments
  rgb = hex: lib.concatMapStringsSep ", "
    (i: toString (lib.fromHexString (builtins.substring i 2 hex) / 255.0))
    [ 1 3 5 ];

  vars = p //
  {
    inherit fontFile;
    host = config.networking.hostName;
    font = config.stylix.fonts.monospace.name;
    snowflake = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
    backgroundRgb = rgb p.background;
    accentRgb = rgb p.accent;
    subtextRgb = rgb p.subtext;
    foregroundRgb = rgb p.foreground;
    warningRgb = rgb p.warning;
  };

  script = pkgs.writeText "palette.script" (subst vars (builtins.readFile ./unlock.script));
in
pkgs.runCommand "plymouth-palette"
{
  nativeBuildInputs = [ pkgs.imagemagick ];
}
  (subst (vars // { inherit script; }) (builtins.readFile ./plymouth-theme.sh))
