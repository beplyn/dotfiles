{ pkgs, username, ... }:

{
  users.defaultUserShell = pkgs.fish;
  users.users."${username}" = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
  };
}
