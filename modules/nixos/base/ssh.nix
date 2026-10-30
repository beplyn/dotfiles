{
  config,
  lib,
  username,
  ...
}:

let
  authorizedKeys = config.users.users.${username}.openssh.authorizedKeys;
  hasAuthorizedKeys = authorizedKeys.keys != [ ] || authorizedKeys.keyFiles != [ ];
in
{
  # opt-in per host
  services.openssh =
  {
    enable = lib.mkDefault false;
    ports = [ 2222 ];
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
