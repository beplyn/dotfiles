{ config, subst, ... }:

let
  vars = config.themes.palette //
  {
    mono = config.stylix.fonts.monospace.name;
  };
in
{
  # midnight-discord for every palette
  equibop.quickCss = subst vars (builtins.readFile ./midnight.css);
}
