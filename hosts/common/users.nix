{
  config,
  lib,
  pkgs,
  username,
  ...
}:

{
  users.defaultUserShell = pkgs.fish;

  # root locked; use sudo
  users.users.root.hashedPassword = "!";

  users.users."${username}" =
  {
    isNormalUser = true;
    description = username;
    extraGroups =
    [
      "networkmanager"
      "wheel"
    ]
    ++ lib.optional config.docker.enable "docker";
  };
}
