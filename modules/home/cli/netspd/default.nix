{
  pkgs,
  ...
}:

{
  home.packages =
  [
    # the flake's package, via lib/mkHost.nix's overlay
    pkgs.netspd
  ];

  xdg.configFile."netspd/config.toml".source = ./netspd.toml;
}
