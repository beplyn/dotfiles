{ config, pkgs, ... }:

{
  imports = [
    ./nvim/main.nix
    ./dev/git.nix
    ./eza.nix
  ];

  home.username = "beplyn";
  home.homeDirectory = "/home/beplyn";
  home.stateVersion = "26.11";

}
