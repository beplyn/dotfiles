{
  lib,
  pkgs,
  osConfig,
  ...
}:

{
  home.packages = lib.optionals osConfig.unfree.enable
  [
    pkgs.claude-code
  ];
}
