{
  config,
  pkgs,
  inputs,
  username,
  email,
  forgejoHost,
  themeName,
  ...
}:

let
  # rebuild [theme]
  # Asks for anything that must never land in the nix store (GPG passphrase,
  # Forgejo token) while we still have a terminal, then switches to
  # <host>-<theme>. Each prompt only shows up when its secret is missing.
  rebuild = pkgs.writeShellApplication
  {
    name = "rebuild";
    runtimeInputs = with pkgs;
    [
      git
      gnupg
      inputs.forgejo-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    text = ''
      theme="''${1:-${themeName}}"
      flake=/etc/nixos

      if [ "$(id -un)" != "${username}" ]; then
        echo "run rebuild as ${username}, not $(id -un)" >&2
        exit 1
      fi

      if ! gpg --list-secret-keys "${email}" >/dev/null 2>&1; then
        echo "No GPG signing key for ${email}, generating one."
        while true; do
          read -rsp "GPG passphrase: " pass; echo
          read -rsp "Repeat passphrase: " pass2; echo
          if [ -z "$pass" ]; then
            echo "passphrase must not be empty" >&2
          elif [ "$pass" != "$pass2" ]; then
            echo "passphrases do not match" >&2
          else
            break
          fi
        done
        # passphrase goes over stdin so it never shows up in argv
        printf '%s' "$pass" | gpg --batch --pinentry-mode loopback --passphrase-fd 0 \
          --quick-generate-key "${username} <${email}>" default default 0
        unset pass pass2
      fi

      if ! fj -H ${forgejoHost} auth list 2>/dev/null | grep -qF "${forgejoHost}"; then
        read -rsp "Forgejo token for ${forgejoHost} (empty to skip): " token; echo
        if [ -n "$token" ]; then
          printf '%s' "$token" | fj -H ${forgejoHost} auth add-token
        fi
        unset token
      fi

      git -C "$flake" add .
      sudo nixos-rebuild switch --flake "$flake#${config.networking.hostName}-$theme"
    '';
  };
in
{
  environment.systemPackages = [ rebuild ];
}
