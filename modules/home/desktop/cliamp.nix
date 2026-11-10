{
  pkgs,
  ...
}:

{
  home.packages =
  [
    # the flake's package, via lib/mkHost.nix's overlay
    pkgs.cliamp
  ];
}
