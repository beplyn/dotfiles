{
  config,
  lib,
  forgejoHost,
  ...
}:

let
  gitHosts = [ forgejoHost "gitlab.com" "github.com" ];
  # per-host key from `rebuild`; upload its .pub to each
  key = "${config.home.homeDirectory}/.ssh/id_ed25519";
in
{
  programs.ssh =
  {
    enable = true;
    enableDefaultConfig = false;
    settings = lib.genAttrs gitHosts (host:
    {
      hostname = host;
      user = "git";
      identityFile = key;
      identitiesOnly = true;
      # forges only take keys; never fall through to a prompt
      preferredAuthentications = "publickey";
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;
    })
    //
    {
      # everywhere else: the same key first, a password prompt if it's refused
      "*" =
      {
        identityFile = key;
        identitiesOnly = true;
        preferredAuthentications = "publickey,keyboard-interactive,password";
        passwordAuthentication = true;
        kbdInteractiveAuthentication = true;
      };
    };
  };
}
