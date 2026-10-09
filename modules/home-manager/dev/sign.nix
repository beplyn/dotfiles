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
  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
  };

  home.packages = with pkgs; [
    gpg-tui
  ];

  home.activation.autoGenerateSigningCredentials = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! ${pkgs.gnupg}/bin/gpg --list-secret-keys "${email}" >/dev/null 2>&1; then
      echo "No GPG secret key found for ${email}, generating one..."
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --pinentry-mode loopback \
        --passphrase "" \
        --quick-generate-key "${username} <${email}>" default default 0
    fi

    ssh_key="${config.home.homeDirectory}/.ssh/codeberg-auth"
    if [ ! -e "$ssh_key" ]; then
      echo "No SSH key found at $ssh_key, generating one..."
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.ssh"
      $DRY_RUN_CMD ${pkgs.openssh}/bin/ssh-keygen -q -t ed25519 -f "$ssh_key" \
        -N "" \
        -C "${username}@${forgejoHost}"
    fi
  '';
}
