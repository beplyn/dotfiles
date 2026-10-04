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
        user = "beplyn";
        identityFile = "/home/beplyn/.ssh/codeberg-auth";
        identitiesOnly = true;
      };
    };
  };
}
