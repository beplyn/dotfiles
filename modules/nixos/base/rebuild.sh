theme="${1:-@themeName@}"
flake=/etc/nixos
# per-host identities, kept in ~/.ssh and the gpg keyring, never in the repo
uid="@username@ (@hostName@) <@email@>"
sshKey="$HOME/.ssh/id_ed25519"

if [ "$(id -un)" != "@username@" ]; then
  echo "run rebuild as @username@, not $(id -un)" >&2
  exit 1
fi

if ! gpg --list-secret-keys "=$uid" >/dev/null 2>&1; then
  echo "No GPG signing key for $uid, generating one."
  while true; do
    read -rsp "GPG passphrase (empty for an unprotected key): " pass; echo
    if [ -z "$pass" ]; then
      read -rp "Key will be stored unencrypted. Continue? [y/N] " insecure
      [[ "$insecure" == [yY]* ]] && break
      continue
    fi
    read -rsp "Repeat passphrase: " pass2; echo
    if [ "$pass" != "$pass2" ]; then
      echo "passphrases do not match" >&2
    else
      break
    fi
  done
  if [ -z "$pass" ]; then
    gpg --batch --pinentry-mode loopback --passphrase '' \
      --quick-generate-key "$uid" ed25519 sign 0
  else
    # via stdin, keeps it out of argv
    printf '%s' "$pass" | gpg --batch --pinentry-mode loopback --passphrase-fd 0 \
      --quick-generate-key "$uid" ed25519 sign 0
  fi
  unset pass pass2 insecure
  echo "Upload the output of \`gpg --armor --export '=$uid'\` to @forgejoHost@ and GitLab."
fi

if [ ! -e "$sshKey" ]; then
  echo "No SSH key at $sshKey, generating one."
  mkdir -p "$(dirname "$sshKey")"
  ssh-keygen -q -t ed25519 -f "$sshKey" -N "" -C "@username@@@hostName@"
  echo "Upload $sshKey.pub to @forgejoHost@ and GitLab."
elif [ "$(cut -d' ' -f3- "$sshKey.pub")" != "@username@@@hostName@" ]; then
  # an older key: only its comment is changed
  ssh-keygen -q -c -f "$sshKey" -C "@username@@@hostName@"
fi

if ! fj -H @forgejoHost@ auth list 2>/dev/null | grep -qF "@forgejoHost@"; then
  read -rsp "Forgejo token for @forgejoHost@ (empty to skip): " token; echo
  if [ -n "$token" ]; then
    printf '%s' "$token" | fj -H @forgejoHost@ auth add-token
  fi
  unset token
fi

git -C "$flake" add .
sudo nixos-rebuild switch --flake "$flake#@hostName@-$theme"
