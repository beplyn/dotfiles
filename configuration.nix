{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix



    ./modules/core/main.nix


    ./modules/system/main.nix


    #./modules/home-manager/home.nix
  ];

  system.stateVersion = "26.11";
}
