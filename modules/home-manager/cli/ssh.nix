{
  config,
  codebergHost,
  ...
}:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "${codebergHost}" = {
        hostname = codebergHost;
        user = "git";
        identityFile = "${config.home.homeDirectory}/.ssh/codeberg-auth";
        identitiesOnly = true;
      };
    };
  };
}
