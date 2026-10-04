{
  ...
}:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "codeberg.org" = {
        hostname = "codeberg.org";
        user = "git";
        identityFile = "/home/beplyn/.ssh/codeberg-auth";
        identitiesOnly = true;
      };
    };
  };
}
