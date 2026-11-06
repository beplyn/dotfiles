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
    # docker is root without sudo, so not on gated hosts
    ++ lib.optional (config.docker.enable && !config.rebuildGate.enable) "docker";
  };
}
