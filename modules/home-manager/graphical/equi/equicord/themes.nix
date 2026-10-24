{ themeName, ... }:

let
  themes = import ./themes/module.nix;
  selected = themes.link.${themeName};
in
{
  programs.equibop.equicord.extraQuickCss =
    if builtins.isPath selected then builtins.readFile selected else ''@import url("${selected}");'';
}
