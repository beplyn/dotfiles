# shellcheck shell=bash
# the checkout /etc/nixos links to; DOTFILES overrides it
flake="${DOTFILES:-$(readlink -f /etc/nixos)}"
host="@hostName@"
theme="@themeName@"
cache="${XDG_CACHE_HOME:-$HOME/.cache}"
# per-host identities, kept in ~/.ssh and the gpg keyring, never in the repo
uid="@username@ (@hostName@) <@email@>"
sshKey="$HOME/.ssh/id_ed25519"

# nerd font glyphs: info, warning, error, secret and yes/no prompts
info() { printf '\e[34m\e[0m %s\n' "$*"; }
warn() { printf '\e[33m\e[0m %s\n' "$*" >&2; }
err() { printf '\e[31m\e[0m %s\n' "$*" >&2; }
upload() { printf '\e[36m\e[0m %s\n' "$*"; }
key=$'\e[35m'""$'\e[0m'
ask=$'\e[35m'""$'\e[0m'

# rebuild [--host HOST] [THEME]; keys, secrets and vars stay with this machine.
while (( $# )); do
  case "$1" in
    -H | --host) host="${2:?--host needs a name}"; shift 2 ;;
    --host=*) host="${1#--host=}"; shift ;;
    -h | --help) echo "usage: rebuild [--host HOST] [THEME]"; exit 0 ;;
    -*) err "unknown option: $1"; exit 2 ;;
    *) theme="$1"; shift ;;
  esac
done
[ -f "$flake/hosts/$host/default.nix" ] || { err "no host $host in $flake/hosts"; exit 1; }

# read_hidden VAR PROMPT: read -s with a * per character; backspace works
read_hidden() {
  local -n into="$1"
  local ch
  into=
  printf '%s' "$2" >&2
  while IFS= read -rsn1 ch; do
    case "$ch" in
      '') break ;;
      $'\x7f' | $'\b')
        if [ -n "$into" ]; then
          into="${into%?}"
          printf '\b \b' >&2
        fi
        ;;
      *)
        into+="$ch"
        printf '*' >&2
        ;;
    esac
  done
  echo >&2
}

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
    read_hidden pass "$key GPG passphrase (empty for an unprotected key): "
    if [ -z "$pass" ]; then
      read -rp "$ask Key will be stored unencrypted. Continue? [y/N] " insecure
      [[ "$insecure" == [yY]* ]] && break
    else
      read_hidden pass2 "$key Repeat passphrase: "
      # shellcheck disable=SC2154 # set by read_hidden
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

# pick PROMPT [FIND TESTS...]: fzf a file under ~ or a USB stick, empty on Esc
# (|| true: find gets SIGPIPE when fzf exits)
pick() {
  local prompt="$1"; shift
  find "$HOME" "/run/media/@username@" -name '.*' -prune -o -type f "$@" -print 2>/dev/null \
    | fzf --prompt "$prompt  " || true
}

# rebuild.secrets: root-only, never in git; delete one to be asked again
restart=()
# shellcheck disable=SC2329 # no calls on hosts without secrets
host_secret() {
  local path="$1" what="$2" prefix="$3" kind="$4" units="$5" value
  sudo test -s "$path" && return
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
    read_hidden value "$key $what for $path (empty to skip): "
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
# this machine's secrets only; an override host has its own
if [ "$host" = "@hostName@" ]; then
@hostSecrets@
fi

# profile picture for hyprlock and the greeter, desktops only
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

# whose machines these are, out of the repo; asks for whatever is missing
dotfiles-vars "$flake/vars/vars.toml" @varsDir@ @staticLan@

# new files reach the flake; nothing else gets staged
git -C "$flake" add --intent-to-add .
sudo nixos-rebuild switch --flake "$flake#$host-$theme" --override-input vars "path:@varsDir@"
# when the last manual switch was, for the greeting on auto-rebuild hosts
sudo install -Dm644 /dev/null /var/lib/rebuild/manual

# units that were waiting on a new secret
if [ ${#restart[@]} -gt 0 ]; then
  sudo systemctl restart "${restart[@]}" || err "restarting ${restart[*]} failed, see journalctl"
fi

# new random wallpaper in the theme's colours (desktop hosts only)
if command -v wallpaper >/dev/null; then
  if wallpaper random; then
    # blurred copy for the greeter (can't read homes, no blur)
    magick "$cache/wallpapers/current.jpg" -resize 1920x1080^ -filter Gaussian -blur 0x20 -level 0%,100%,0.85 png24:- \
      | sudo install -Dm644 /dev/stdin /var/lib/wallpaper/current.png
  else
    warn "wallpaper random failed, keeping the current wallpaper"
  fi
fi

# rendered ~/.pfp (or the snowflake) for the greeter, which can't read homes
if command -v pfp >/dev/null && pfp; then
  sudo install -Dm644 "$cache/pfp.png" /var/lib/AccountsService/icons/@username@
fi
