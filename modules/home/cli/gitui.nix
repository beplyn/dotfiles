{ config, subst, ... }:

let
  p = config.themes.palette;
in

{
  # own palette theme instead
  stylix.targets.gitui.enable = false;

  programs.gitui =
  {
    enable = true;
    # default keys; an empty file errors
    keyConfig = "()";
    theme = subst p (builtins.readFile ./gitui.ron);
  };
}
