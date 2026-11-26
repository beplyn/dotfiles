{
  pkgs,
  ...
}:

{
  home.packages =
  [
    # native Discord client in Rust, via lib/mkHost.nix's overlay
    pkgs.serein
  ];
}
