{
  config,
  lib,
  username,
  ...
}:

let
  authorizedKeys = config.users.users.${username}.openssh.authorizedKeys;
  hasAuthorizedKeys = authorizedKeys.keys != [ ] || authorizedKeys.keyFiles != [ ];
  # the gate's PAM stack: password + the sudo TOTP
  totp = config.rebuildGate.enable;
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
      # gated: a key, else password + TOTP; otherwise password only until a key is set
      PasswordAuthentication = !totp && !hasAuthorizedKeys;
      KbdInteractiveAuthentication = totp;
      AuthenticationMethods = lib.mkIf totp "publickey keyboard-interactive:pam";
      PermitRootLogin = "no";
    };
  };
}
