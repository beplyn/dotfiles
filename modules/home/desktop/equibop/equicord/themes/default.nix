{ config, subst, themeName, ... }:

let
  vars = config.themes.palette //
  {
    mono = config.stylix.fonts.monospace.name;
    corner = themeName;
  };
in
{
  # midnight-discord for every palette
  programs.equibop.equicord.extraQuickCss = subst vars (builtins.readFile ./midnight.css);
}
