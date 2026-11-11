{
  pkgs,
  ...
}:

{
  home.packages =
  [
    # offline ELTE specification editor, via lib/mkHost.nix's overlay
    pkgs.speci-local
  ];
}
