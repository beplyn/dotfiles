{
  config,
  lib,
  username,
  keys,
  ...
}:

let
  port = 2222;
  authorizedKeys = config.users.users.${username}.openssh.authorizedKeys;
  hasAuthorizedKeys = authorizedKeys.keys != [ ] || authorizedKeys.keyFiles != [ ];
in
{
  # every host's login key from keys/ is trusted
  users.users.${username}.openssh.authorizedKeys.keyFiles = keys.userKeys;

  # host keys from keys/, so connecting to our own hosts needs no TOFU prompt
  programs.ssh.knownHosts = lib.mapAttrs (host: file:
  {
    hostNames = [ "[${host}]:${toString port}" ];
    publicKeyFile = file;
  }) keys.hostKeys;

  # opt-in per host
  services.openssh =
  {
    enable = lib.mkDefault false;
    ports = [ port ];
    openFirewall = true;
    settings =
    {
      # password fallback until a key is set
      PasswordAuthentication = !hasAuthorizedKeys;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
