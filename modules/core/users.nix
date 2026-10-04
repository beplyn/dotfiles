{ config, pkgs, ... }:

{
  users.defaultUserShell = pkgs.fish;
  users.users."beplyn" = {
    isNormalUser = true;
    description = "beplyn";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      #  thunderbird
    ];
  };
}
