theme="${1:-@themeName@}"
flake=/etc/nixos

if [ "$(id -un)" != "@username@" ]; then
  echo "run rebuild as @username@, not $(id -un)" >&2
  exit 1
fi

if ! gpg --list-secret-keys "@email@" >/dev/null 2>&1; then
  echo "No GPG signing key for @email@, generating one."
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
  # via stdin, keeps it out of argv
  printf '%s' "$pass" | gpg --batch --pinentry-mode loopback --passphrase-fd 0 \
    --quick-generate-key "@username@ <@email@>" default default 0
  unset pass pass2
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
