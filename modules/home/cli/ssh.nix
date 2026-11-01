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
    # per-host key from `rebuild`; upload its .pub to each
    settings = lib.genAttrs gitHosts (host:
    {
      hostname = host;
      user = "git";
      identityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      identitiesOnly = true;
    });
  };
}
