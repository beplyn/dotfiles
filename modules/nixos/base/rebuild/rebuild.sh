theme="${1:-@themeName@}"
flake=/etc/nixos
cache="${XDG_CACHE_HOME:-$HOME/.cache}"
# per-host identities, kept in ~/.ssh and the gpg keyring, never in the repo
uid="@username@ (@hostName@) <@email@>"
sshKey="$HOME/.ssh/id_ed25519"

# nerd font glyphs in the terminal's palette: info, warning, error, secret and yes/no prompts
info() { printf '\e[34m\e[0m %s\n' "$*"; }
warn() { printf '\e[33m\e[0m %s\n' "$*" >&2; }
err() { printf '\e[31m\e[0m %s\n' "$*" >&2; }
upload() { printf '\e[36m\e[0m %s\n' "$*"; }
key=$'\e[35m'""$'\e[0m'
ask=$'\e[35m'""$'\e[0m'

if [ "$(id -un)" != "@username@" ]; then
  err "run rebuild as @username@, not $(id -un)"
  exit 1
fi

# an expired or revoked key is replaced, not renewed
for fpr in $(gpg --with-colons --list-secret-keys "=$uid" 2>/dev/null \
    | awk -F: '$1 == "sec" { dead = ($2 == "e" || $2 == "r") } $1 == "fpr" && dead { print $10; dead = 0 }'); do
  warn "GPG key $fpr for $uid expired or revoked, replacing it."
  gpg --batch --yes --delete-secret-and-public-key "$fpr"
done

if ! gpg --list-secret-keys "=$uid" >/dev/null 2>&1; then
  info "No GPG signing key for $uid, generating one."
  while true; do
    read -rsp "$key GPG passphrase (empty for an unprotected key): " pass; echo
    if [ -z "$pass" ]; then
      read -rp "$ask Key will be stored unencrypted. Continue? [y/N] " insecure
      [[ "$insecure" == [yY]* ]] && break
    else
      read -rsp "$key Repeat passphrase: " pass2; echo
      [ "$pass" = "$pass2" ] && break
      err "passphrases do not match"
    fi
  done
  # via stdin, keeps it out of argv; an empty one leaves the key unprotected
  printf '%s' "$pass" | gpg --batch --pinentry-mode loopback --passphrase-fd 0 \
    --quick-generate-key "$uid" ed25519 sign 6m
  unset pass pass2
  upload "Upload the output of \`gpg --armor --export '=$uid'\` to @forgejoHost@."
fi

if [ ! -e "$sshKey" ]; then
  info "No SSH key at $sshKey, generating one."
  mkdir -p "$(dirname "$sshKey")"
  ssh-keygen -q -t ed25519 -f "$sshKey" -N "" -C "@username@@@hostName@"
  upload "Upload $sshKey.pub to @forgejoHost@."
elif [ "$(cut -d' ' -f3- "$sshKey.pub")" != "@username@@@hostName@" ]; then
  # an older key: only its comment is changed
  ssh-keygen -q -c -f "$sshKey" -C "@username@@@hostName@"
fi

# hosts without fj skip the token
if @forgejo@ && ! fj -H @forgejoHost@ auth list 2>/dev/null | grep -qF "@forgejoHost@"; then
  read -rsp "$key Forgejo token for @forgejoHost@ (empty to skip): " token; echo
  if [ -n "$token" ]; then
    printf '%s' "$token" | fj -H @forgejoHost@ auth add-token
  fi
  unset token
fi

# gated hosts: the gate reports missing secrets, so a signed rebuild needs no sudo password
if @gated@; then
  gateState="$(sudo @gate@ state)"
fi

# pick PROMPT [FIND TESTS...]: a file under ~ or a mounted stick (hidden dirs skipped), empty on Esc;
# find gets SIGPIPE once fzf exits, hence || true
pick() {
  local prompt="$1"; shift
  find "$HOME" "/run/media/@username@" -name '.*' -prune -o -type f "$@" -print 2>/dev/null \
    | fzf --prompt "$prompt  " || true
}

# host secrets (rebuild.secrets): root-only, never in the repo; delete one to be asked again
restart=()
# shellcheck disable=SC2329 # no calls on hosts without secrets
host_secret() {
  local path="$1" what="$2" prefix="$3" kind="$4" units="$5" value
  if @gated@; then
    grep -qxF "missing $path" <<<"$gateState" || return
  else
    sudo test -s "$path" && return
  fi
  # umask reaches sudo, so new dirs are 0700
  (umask 077 && sudo mkdir -p "${path%/*}")
  if [ "$kind" = file ]; then
    value="$(pick "File with the $what for $path (Esc: skip)")"
    if [ -z "$value" ]; then
      warn "$path still missing"
      return
    elif [ ! -r "$value" ]; then
      err "$value is not readable, $path still missing"
      return
    fi
    sudo install -m 0400 -o root -g root "$value" "$path"
  else
    read -rsp "$key $what for $path (empty to skip): " value; echo
    if [ -z "$value" ]; then
      warn "$path still missing"
      return
    fi
    # via stdin, keeps it out of argv
    printf '%s%s\n' "$prefix" "$value" | sudo install -m 0400 -o root -g root /dev/stdin "$path"
  fi
  if [ -n "$units" ]; then
    # shellcheck disable=SC2206 # space-separated unit names
    restart+=($units)
  fi
}
@hostSecrets@

# profile picture for hyprlock and the greeter (desktop hosts only); asked for until there is one
if @desktop@ && [ ! -e "$HOME/.pfp" ]; then
  pic="$(pick 'Profile picture for ~/.pfp (Esc: snowflake)' \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \))"
  if [ -n "$pic" ]; then
    if magick identify "${pic}[0]" >/dev/null 2>&1; then
      cp -f "$pic" "$HOME/.pfp"
    else
      err "$pic is not a readable image, ~/.pfp unchanged"
    fi
  fi
fi

if @gated@; then
  # the gate builds commits, not the working tree: send the ones it lacks, it checks the signature
  if [ -n "$(git -C "$flake" status --porcelain)" ]; then
    warn "uncommitted changes in $flake are not deployed; commit (and sign) them first"
  fi
  rev="$(git -C "$flake" rev-parse HEAD)"
  base="$(sed -n 's/^deployed //p' <<<"$gateState")"
  if [ "$base" = "$rev" ]; then
    sudo @gate@ deploy "$theme" "$rev" </dev/null
  elif [ -n "$base" ] && git -C "$flake" merge-base --is-ancestor "$base" "$rev" 2>/dev/null; then
    git -C "$flake" bundle create -q - HEAD "^$base" | sudo @gate@ deploy "$theme" "$rev"
  else
    git -C "$flake" bundle create -q - HEAD | sudo @gate@ deploy "$theme" "$rev"
  fi
else
  # new files reach the flake; nothing else gets staged
  git -C "$flake" add --intent-to-add .
  sudo nixos-rebuild switch --flake "$flake#@hostName@-$theme"
fi

# units that were waiting on a new secret
if [ ${#restart[@]} -gt 0 ]; then
  sudo systemctl restart "${restart[@]}" || err "restarting ${restart[*]} failed, see journalctl"
fi

# new random wallpaper in the theme's colours (desktop hosts only)
if command -v wallpaper-pick >/dev/null; then
  if wallpaper-pick; then
    # blurred copy for the greeter (can't read homes, no blur)
    magick "$cache/wallpaper/current.png" -resize 1920x1080^ -filter Gaussian -blur 0x20 -level 0%,100%,0.85 png24:- \
      | sudo install -Dm644 /dev/stdin /var/lib/wallpaper/current.png
  else
    warn "wallpaper-pick failed, keeping the current wallpaper"
  fi
fi

# rendered ~/.pfp (or the snowflake) for the greeter, which can't read homes
if command -v pfp >/dev/null && pfp; then
  sudo install -Dm644 "$cache/pfp.png" /var/lib/AccountsService/icons/@username@
fi
