theme="${1:-@themeName@}"
flake=/etc/nixos
cache="${XDG_CACHE_HOME:-$HOME/.cache}"
# per-host identities, kept in ~/.ssh and the gpg keyring, never in the repo
uid="@username@ (@hostName@) <@email@>"
sshKey="$HOME/.ssh/id_ed25519"

if [ "$(id -un)" != "@username@" ]; then
  echo "run rebuild as @username@, not $(id -un)" >&2
  exit 1
fi

# an expired or revoked key is replaced, not renewed
for fpr in $(gpg --with-colons --list-secret-keys "=$uid" 2>/dev/null \
    | awk -F: '$1 == "sec" { dead = ($2 == "e" || $2 == "r") } $1 == "fpr" && dead { print $10; dead = 0 }'); do
  echo "GPG key $fpr for $uid expired or revoked, replacing it."
  gpg --batch --yes --delete-secret-and-public-key "$fpr"
done

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
      --quick-generate-key "$uid" ed25519 sign 6m
  else
    # via stdin, keeps it out of argv
    printf '%s' "$pass" | gpg --batch --pinentry-mode loopback --passphrase-fd 0 \
      --quick-generate-key "$uid" ed25519 sign 6m
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

# copy new wallpapers into the repo, never overwrite
wallpapers="$HOME/Pictures/Wallpapers"
if [ -d "$wallpapers" ]; then
  cp -r --update=none "$wallpapers/." "$flake/modules/home/wm/shell/quickshell/wallpapers/"
fi

# profile picture for hyprlock and the greeter (desktop hosts only)
if @desktop@; then
  if [ -e "$HOME/.pfp" ]; then keep="keep the current one"; else keep="snowflake"; fi
  read -erp "Picture to copy to ~/.pfp (empty: $keep): " pic || pic=
  pic="${pic/#\~/$HOME}"
  if [ -n "$pic" ] && ! [ "$pic" -ef "$HOME/.pfp" ]; then
    if magick identify "${pic}[0]" >/dev/null 2>&1; then
      cp -f "$pic" "$HOME/.pfp"
    else
      echo "$pic is not a readable image, ~/.pfp unchanged" >&2
    fi
  fi
  unset keep pic
fi

# new files reach the flake; nothing else gets staged
git -C "$flake" add --intent-to-add .
sudo nixos-rebuild switch --flake "$flake#@hostName@-$theme"

# new random wallpaper in the theme's colours (desktop hosts only)
if command -v wallpaper-pick >/dev/null; then
  if wallpaper-pick; then
    # blurred copy for the greeter (can't read homes, no blur)
    magick "$cache/wallpaper/current.png" -resize 1920x1080^ -filter Gaussian -blur 0x20 -level 0%,100%,0.85 png24:- \
      | sudo install -Dm644 /dev/stdin /var/lib/wallpaper/current.png
  else
    echo "wallpaper-pick failed, keeping the current wallpaper" >&2
  fi
fi

# rendered ~/.pfp (or the snowflake) for the greeter, which can't read homes
if command -v pfp >/dev/null && pfp; then
  sudo install -Dm644 "$cache/pfp.png" /var/lib/AccountsService/icons/@username@
fi
