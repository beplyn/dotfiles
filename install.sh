#!/usr/bin/env bash
# Fresh NixOS install: repo to ~/<reponame>, pick host and theme, generate
# hardware config, link /etc/nixos, build. Works from a checkout or `curl | bash`.
set -euo pipefail

REPO_URL="${REPO_URL:-https://codeberg.org/beplyn/dotfiles.git}"
NIX_CONFIG="${NIX_CONFIG:-}"$'\n'"experimental-features = nix-command flakes"
export NIX_CONFIG

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

# Read from the terminal so prompts still work under `curl | bash`.
ask() {
  local prompt="$1" default="${2:-}" reply
  read -r -p "$prompt" reply < /dev/tty
  printf '%s' "${reply:-$default}"
}

confirm() {
  local reply
  reply="$(ask "$1 " "$2")"
  [[ "$reply" =~ ^[Yy] ]]
}

# Pick one entry from a list, by number or by name.
choose() {
  local prompt="$1"; shift
  local options=("$@") i reply
  for i in "${!options[@]}"; do
    printf '  %d) %s\n' "$((i + 1))" "${options[$i]}" > /dev/tty
  done
  while true; do
    reply="$(ask "$prompt")"
    if [[ "$reply" =~ ^[0-9]+$ ]] && (( reply >= 1 && reply <= ${#options[@]} )); then
      printf '%s' "${options[$((reply - 1))]}"; return
    fi
    for i in "${options[@]}"; do
      [[ "$reply" == "$i" ]] && { printf '%s' "$i"; return; }
    done
    warn "Not a valid choice: $reply" > /dev/tty
  done
}

ensure_git() {
  command -v git > /dev/null && return
  info "git not found, fetching a temporary one from the Nix store"
  local git_bin=""
  if command -v nix-shell > /dev/null; then
    git_bin="$(nix-shell -p git --run 'command -v git' 2> /dev/null | tail -n1)" || true
  fi
  if [[ ! -x "$git_bin" ]]; then
    git_bin="$(nix build --no-link --print-out-paths nixpkgs#git | head -n1)/bin/git"
  fi
  [[ -x "$git_bin" ]] || die "Could not get git from nixpkgs"
  PATH="$(dirname "$git_bin"):$PATH"
  export PATH
}

[[ $EUID -ne 0 ]] || die "Run this as your normal user, not root (sudo is used where needed)."
command -v sudo > /dev/null || die "sudo is required"

ensure_git

# --- 1. Get the repo into ~/<reponame> --------------------------------------

script_dir=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [[ -n "$script_dir" && -f "$script_dir/flake.nix" ]]; then
  repo_name="$(basename "$script_dir")"
else
  repo_name="$(basename "$REPO_URL" .git)"
fi
repo_dir="$HOME/$repo_name"

if [[ -n "$script_dir" && "$script_dir" == "$repo_dir" ]]; then
  info "Running from $repo_dir, nothing to copy"
elif [[ -e "$repo_dir" ]]; then
  [[ -f "$repo_dir/flake.nix" ]] || die "$repo_dir exists but is not this repo; move it out of the way first."
  warn "$repo_dir already exists, using it as is"
elif [[ -n "$script_dir" && -f "$script_dir/flake.nix" ]]; then
  info "Copying $script_dir to $repo_dir"
  cp -a "$script_dir" "$repo_dir"
else
  info "Cloning $REPO_URL to $repo_dir"
  git clone "$REPO_URL" "$repo_dir"
fi

cd "$repo_dir"

# --- 2. Host and theme ------------------------------------------------------

mapfile -t hosts < <(find hosts -mindepth 1 -maxdepth 1 -type d ! -name common -printf '%f\n' | sort)
(( ${#hosts[@]} )) || die "No hosts found in $repo_dir/hosts"

# Themes come from the `themes = [ ... ];` list in flake.nix.
mapfile -t themes < <(sed -n '/^\s*themes =/,/\];/ s/^\s*"\([^"]*\)".*/\1/p' flake.nix)
(( ${#themes[@]} )) || die "No themes found in flake.nix"

echo
info "Which host is this machine?"
host="$(choose "Host: " "${hosts[@]}")"
echo
info "Which theme?"
theme="$(choose "Theme: " "${themes[@]}")"

host_dir="hosts/$host"
hw="$host_dir/hardware.nix"

# unfree.enable (on by default) lives in the host's default.nix
echo
sed -i '/^\s*unfree\.enable\s*=/d' "$host_dir/default.nix"
if confirm "Allow the unfree software in the repo (claude-code, MS Office fonts, Steam)? [Y/n]" y; then
  info "Unfree software allowed"
else
  sed -i '/networking\.hostName/a\  unfree.enable = false;' "$host_dir/default.nix"
  info "Unfree software left out"
fi

# --- 3. Hardware config -----------------------------------------------------

# real = nixos-generate-config output; else a placeholder or hand tuning
is_generated() { [[ -f "$1" ]] && grep -q 'Do not modify this file' "$1"; }

echo
regenerate=false
if is_generated "$hw"; then
  info "$host already has a generated hardware config."
  warn "If this disk was reformatted the UUIDs in it are stale and the system won't boot."
  confirm "Regenerate it from this machine? [y/N]" n && regenerate=true
else
  info "$host has no generated hardware config yet."
  warn "Without one it has no file systems or kernel modules for this machine and won't boot."
  confirm "Generate it from this machine? [Y/n]" y && regenerate=true
fi

if $regenerate; then
  generated="$(sudo nixos-generate-config --show-hardware-config)"

  if [[ -f "$hw" ]]; then
    if is_generated "$hw"; then
      cp "$hw" "$hw.bak"
      info "Old config saved to $hw.bak (untracked)"
    elif ! grep -q 'PLACEHOLDER' "$hw"; then
      # keep hand tuning (e.g. anvil's) beside the generated file
      mv "$hw" "$host_dir/hardware-extra.nix"
      sed -i 's|\./hardware\.nix|./hardware.nix ./hardware-extra.nix|' "$host_dir/default.nix"
      git add "$host_dir/hardware-extra.nix"
      info "Kept hand-written settings as $host_dir/hardware-extra.nix"
    fi
  fi

  # a single LUKS device goes to encryption.nix (as cryptroot), not hardware.nix
  mapfile -t luks < <(grep -E '^\s*boot\.initrd\.luks\.devices\.' <<< "$generated" || true)
  sed -i '/^\s*encryption\.\(enable\|device\)\s*=/d' "$host_dir/default.nix"
  if (( ${#luks[@]} == 1 )); then
    luks_dev="$(sed -n 's/.*\.device\s*=\s*"\([^"]*\)".*/\1/p' <<< "${luks[0]}")"
    generated="$(grep -vE '^\s*boot\.initrd\.luks\.devices\.' <<< "$generated")"
    sed -i "/networking\.hostName/a\\  encryption.device = \"$luks_dev\";" "$host_dir/default.nix"
    info "LUKS root detected ($luks_dev), using the themed unlock prompt"
  else
    sed -i '/networking\.hostName/a\  encryption.enable = false;' "$host_dir/default.nix"
    if (( ${#luks[@]} > 1 )); then
      warn "Multiple LUKS devices found; left them in hardware.nix and disabled the encryption module."
    else
      info "No LUKS detected, disabling the encryption module"
    fi
  fi

  printf '%s\n' "$generated" > "$hw"
  info "Wrote $hw"
fi

# --- 4. Link /etc/nixos -----------------------------------------------------

if [[ -L /etc/nixos ]]; then
  sudo rm /etc/nixos
elif [[ -e /etc/nixos ]]; then
  backup="/etc/nixos.bak-$(date +%Y%m%d-%H%M%S)"
  sudo mv /etc/nixos "$backup"
  info "Moved the old /etc/nixos to $backup"
fi
sudo ln -s "$repo_dir" /etc/nixos
info "Linked /etc/nixos -> $repo_dir"

user="$(sed -n 's/^\s*username = "\([^"]*\)";.*/\1/p' flake.nix | head -n1)"
[[ "$USER" == "$user" ]] || warn "You are '$USER', but the config sets up the user '$user'."

target="$host-$theme"
echo
# switching live from the installer fails; install for the next boot
built=false
if confirm "Build $target and install it for the next boot? [Y/n]" y; then
  info "Building $target"
  system="$(nix build --no-link --print-out-paths \
    "$repo_dir#nixosConfigurations.$target.config.system.build.toplevel")"
  sudo nix-env -p /nix/var/nix/profiles/system --set "$system"
  sudo "$system/bin/switch-to-configuration" boot
  info "Installed $system"
  built=true
else
  info "Later, run: sudo nixos-rebuild boot --flake /etc/nixos#$target"
fi

# keys, host secrets (rebuild.secrets) and ~/.pfp come from rebuild, not from here
# shellcheck disable=SC2016 # nix expression, not shell
mapfile -t secrets < <(nix eval --raw "$repo_dir#nixosConfigurations.$target.config.rebuild.secrets" \
  --apply 's: builtins.concatStringsSep "\n" (map (p: "${p}: ${s.${p}.description}") (builtins.attrNames s))' \
  2> /dev/null || true)
echo
info "After the reboot, run \`rebuild\` to set up the GPG and SSH keys and switch to $target."
if (( ${#secrets[@]} )); then
  warn "$host needs these secrets; rebuild asks for them, and their services fail until then:"
  printf '     %s\n' "${secrets[@]}"
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo
  info "The repo has changes from this install; commit them when you're ready:"
  git status --short
fi

if $built; then
  echo
  confirm "Reboot now? [Y/n]" y && sudo reboot
  info "Reboot when you're ready to start $target."
fi
