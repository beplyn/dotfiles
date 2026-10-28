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
      "gitlab.com" = {
        hostname = "gitlab.com";
        user = "git";
        identityFile = "${config.home.homeDirectory}/.ssh/gitlab-auth";
        identitiesOnly = true;
      };
      "${forgejoHost}" = {
        hostname = forgejoHost;
        user = "git";
        identityFile = "${config.home.homeDirectory}/.ssh/codeberg-auth";
        identitiesOnly = true;
      };
    };
  };
}
