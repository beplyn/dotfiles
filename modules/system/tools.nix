{
  inputs,
  config,
  pkgs,
  ...
}:

{
  programs = {
    yazi = {
      enable = true;
    };
  };
}
