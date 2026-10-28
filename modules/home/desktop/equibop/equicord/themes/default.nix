{ themeName, ... }:

let
  links =
  {
    catppuccin = "https://catppuccin.github.io/discord/dist/catppuccin-mocha-mauve.theme.css";
    nord = "https://raw.githubusercontent.com/refact0r/midnight-discord/refs/heads/master/themes/flavors/midnight-nord.theme.css";
    gruvbox = ./gruvbox.css;
  };
  selected = links.${themeName};
in
{
  programs.equibop.equicord.extraQuickCss =
    if builtins.isPath selected then builtins.readFile selected else ''@import url("${selected}");'';
}
