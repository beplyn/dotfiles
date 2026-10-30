{ config, lib, ... }:

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
    theme = lib.replaceStrings
      (map (n: "@${n}@") (lib.attrNames p))
      (lib.attrValues p)
      (builtins.readFile ./gitui.ron);
  };
}
