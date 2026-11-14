{
  config,
  lib,
  ...
}:

let
  # root-only, google-authenticator format (a bare base32 line is enough)
  totpSecret = "/var/secrets/ssh-totp.secret";
  enabled = config.services.openssh.enable;
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
      # a key, else password + TOTP through PAM's keyboard-interactive
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = true;
      AuthenticationMethods = "publickey keyboard-interactive:pam";
      PermitRootLogin = "no";
    };
  };

  # password, then TOTP; sudo stays password only
  security.pam.services.sshd = lib.mkIf enabled
  {
    # PasswordAuthentication off would drop pam_unix
    unixAuth = lib.mkForce true;
    googleAuthenticator =
    {
      enable = true;
      # password only until the seed is there, so the first switch can't lock ssh out
      allowNullOTP = true;
    };
    # root-owned, so a user shell can't swap in its own seed
    rules.auth.google_authenticator.settings =
    {
      secret = totpSecret;
      user = "root";
    };
  };

  rebuild.secrets = lib.mkIf enabled
  {
    ${totpSecret}.description = "TOTP seed (base32) for ssh logins without a key";
  };
}
