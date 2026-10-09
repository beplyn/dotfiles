{
  config,
  forgejoHost,
  ...
}:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "${forgejoHost}" = {
        hostname = forgejoHost;
        user = "git";
        identityFile = "${config.home.homeDirectory}/.ssh/codeberg-auth";
        identitiesOnly = true;
      };
    };
  };
}
