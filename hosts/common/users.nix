{ pkgs, username, ... }:

{
  users.defaultUserShell = pkgs.fish;

  # Locked: no password login for root; administration goes through sudo.
  users.users.root.hashedPassword = "!";

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
