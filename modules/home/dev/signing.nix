{
  pkgs,
  lib,
  config,
  username,
  email,
  forgejoHost,
  ...
}:

{
  programs.gpg.enable = true;

  services.gpg-agent =
  {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
  };

  home.packages = with pkgs;
  [
    gpg-tui
  ];

  # The GPG signing key is created by `rebuild`, which can prompt for its
  # passphrase; activation has no terminal.
  home.activation.autoGenerateSigningCredentials = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for pair in "codeberg-auth:${forgejoHost}" "gitlab-auth:gitlab.com"; do
      ssh_key="${config.home.homeDirectory}/.ssh/''${pair%%:*}"
      if [ ! -e "$ssh_key" ]; then
        echo "No SSH key found at $ssh_key, generating one..."
        run ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.ssh"
        run ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -f "$ssh_key" \
          -N "" \
          -C "${username}@''${pair#*:}"
      fi
    done
  '';
}
