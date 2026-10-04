{ config, pkgs, ... }:

{
  imports = [
    ./git.nix
    ./nvim.nix
  ];
}
