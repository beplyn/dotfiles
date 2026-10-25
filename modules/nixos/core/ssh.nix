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
  # Off unless a host opts in (beacon, shulker).
  services.openssh = {
    enable = lib.mkDefault false;
    ports = [ 2222 ];
    openFirewall = true;
    settings = {
      # Keep password login as a fallback until a key is authorized.
      PasswordAuthentication = !hasAuthorizedKeys;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
}
