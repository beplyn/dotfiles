{ config, subst, ... }:

let
  vars = config.themes.palette //
  {
    mono = config.stylix.fonts.monospace.name;
  };
in
{
  # midnight-discord for every palette
  programs.nixcord.quickCss = subst vars (builtins.readFile ./midnight.css);
}
