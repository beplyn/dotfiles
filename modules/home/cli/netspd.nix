{
  inputs,
  pkgs,
  ...
}:

{
  home.packages =
  [
    inputs.netspd.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  xdg.configFile."netspd/config.toml".source = ./netspd.toml;
}
