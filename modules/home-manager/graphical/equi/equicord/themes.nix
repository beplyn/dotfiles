{
  config,
  lib,
  pkgs,
  ...
}:
let
  themes = import ./themes/module.nix;

  activeThemeKey =
    let
      active = config.themes.active or "catppuccin";
    in
    if lib.hasInfix "gruvbox" active then
      "gruvbox"
    else if lib.hasInfix "nord" active then
      "nord"
    else
      "catppuccin";

  selected = themes.link.${activeThemeKey};
  isLocal = builtins.isPath selected;

  cssContent = if isLocal then builtins.readFile selected else ''@import url("${selected}");'';
in
{
  programs.equibop.equicord.settings = {
    useQuickCss = true;
    enabledThemeLinks = [ ];
    enabledThemes = [ ];
  };

  xdg.configFile."equibop/settings/quickCss.css".text = cssContent;
}
