{
  config,
  lib,
  forgejoHost,
  ...
}:

let
  gitHosts = [ forgejoHost "gitlab.com" ];
in
{
  programs.ssh =
  {
    enable = true;
    enableDefaultConfig = false;
    # one key per host (beplyn@<host>), made by `rebuild`; upload ~/.ssh/id_ed25519.pub to each
    settings = lib.genAttrs gitHosts (host:
    {
      hostname = host;
      user = "git";
      identityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      identitiesOnly = true;
    });
  };
}
