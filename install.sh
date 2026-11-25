#!/usr/bin/env bash
# fresh NixOS install: clone, pick host and theme, hardware config, build.
# Works from a checkout or `curl | bash`.
set -Eeuo pipefail
# a failing command inside $(...) stops the script too, not just the subshell
shopt -s inherit_errexit

# asked for under `curl | bash`; a checkout uses itself
REPO_URL="${REPO_URL:-}"
# whose machines these are (docs/vars.md), root-only; the rebuild module has it too
VARS_DIR=/var/secrets/dotfiles
NIX_CONFIG="${NIX_CONFIG:-}"$'\n'"experimental-features = nix-command flakes"
export NIX_CONFIG

# sudo resets the environment, so pass the flakes setting through
sudo_nix() { sudo env NIX_CONFIG="$NIX_CONFIG" nix "$@"; }

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
# stops the whole install, also when called from inside $(...)
die() {
  printf '\033[1;31mxx\033[0m %s\n' "$*" >&2
  kill -TERM $$
  exit 1
}

trap 'warn "stopped at line $LINENO: $BASH_COMMAND"' ERR
trap 'warn "stopped by you"; exit 130' INT
# die signals the main shell from inside $(...); exit with failure, not "terminated"
trap 'exit 1' TERM

# the host's files are snapshotted before they are edited; a failed run puts them back
snapshot=""
restore_host() {
  local rc=$?
  if (( rc != 0 )) && [[ -n "$snapshot" && -d "$snapshot" ]]; then
    rm -rf "$host_dir"
    cp -a "$snapshot/." "$host_dir/"
    warn "Put $host_dir back the way it was before this run."
  fi
  if [[ -n "$snapshot" ]]; then
    rm -rf "$snapshot"
  fi
}

# Read from the terminal so prompts still work under `curl | bash`.
ask() {
  local prompt="$1" default="${2:-}" reply
  read -r -p "$prompt" reply < /dev/tty || die "No answer: the terminal closed."
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

# need COMMAND [HINT]: stop early when a required program is missing
need() {
  command -v "$1" > /dev/null || die "$1 is not installed${2:+ ($2)}"
}

# a temporary tool from nixpkgs when it's not installed: ensure_tool COMMAND PACKAGE
ensure_tool() {
  command -v "$1" > /dev/null && return 0
  info "$1 not found, fetching a temporary one from the Nix store"
  local out=""
  # nix's own error is shown above; an empty result is handled below
  out="$(nix build --no-link --print-out-paths "nixpkgs#$2" | head -n1)" || true
  [[ -n "$out" && -x "$out/bin/$1" ]] \
    || die "Could not get $1 from nixpkgs (is there a network connection?)"
  PATH="$out/bin:$PATH"
  export PATH
}

ensure_git() {
  command -v git > /dev/null && return 0
  info "git not found, fetching a temporary one from the Nix store"
  local git_bin="" out=""
  if command -v nix-shell > /dev/null; then
    git_bin="$(nix-shell -p git --run 'command -v git' 2> /dev/null | tail -n1)" || true
  fi
  if [[ ! -x "$git_bin" ]]; then
    out="$(nix build --no-link --print-out-paths nixpkgs#git | head -n1)" || true
    if [[ -n "$out" ]]; then
      git_bin="$out/bin/git"
    fi
  fi
  [[ -x "$git_bin" ]] || die "Could not get git from nixpkgs (is there a network connection?)"
  PATH="$(dirname "$git_bin"):$PATH"
  export PATH
}

# edit a host's default.nix: the line goes after networking.hostName
insert_after_hostname() {
  local file="$1" line="$2"
  grep -q 'networking\.hostName' "$file" \
    || die "$file has no networking.hostName line to add '$line' after"
  sed -i "/networking\.hostName/a\\  $line" "$file"
}

[[ $EUID -ne 0 ]] || die "Run this as your normal user, not root (sudo is used where needed)."
[[ -n "${HOME:-}" ]] || die "HOME is not set"
user_name="${USER:-$(id -un)}"

# every question is asked on the terminal, so there has to be one
(: < /dev/tty) 2> /dev/null \
  || die "No terminal to ask on. Run this from a terminal, not from a script or a cron job."

need sudo
need nix "the Nix package manager; the NixOS installer has it"

# ask for the sudo password once now, not in the middle of the build
info "sudo is needed for the hardware config, /etc/nixos and the build."
sudo -v || die "sudo failed (wrong password, or your user cannot use sudo)."

ensure_git
ensure_tool yq yq-go

# --- 1. Get the repo into ~/<reponame> --------------------------------------

# the checkout this runs from; empty under `curl | bash`
src=""
if [[ -n "${BASH_SOURCE[0]:-}" && -f "$(dirname "${BASH_SOURCE[0]}")/flake.nix" ]]; then
  src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
if [[ -z "$src" && -z "$REPO_URL" ]]; then
  REPO_URL="$(ask "Repo to install from (https URL of your dotfiles): ")"
  REPO_URL="${REPO_URL// /}"
  [[ -n "$REPO_URL" ]] || die "No repo given"
  [[ "$REPO_URL" =~ ^(https?://|ssh://|git@|file://) ]] \
    || die "'$REPO_URL' does not look like a git URL (expected https://...)"
fi
repo_dir="$HOME/$(basename "${src:-${REPO_URL%.git}}")"

if [[ "$src" == "$repo_dir" ]]; then
  info "Running from $repo_dir, nothing to copy"
elif [[ -e "$repo_dir" ]]; then
  [[ -f "$repo_dir/flake.nix" ]] || die "$repo_dir exists but is not this repo; move it out of the way first."
  warn "$repo_dir already exists, using it as is"
elif [[ -n "$src" ]]; then
  info "Copying $src to $repo_dir"
  cp -a "$src" "$repo_dir" || die "Copying $src to $repo_dir failed."
else
  info "Cloning $REPO_URL to $repo_dir"
  git clone "$REPO_URL" "$repo_dir" \
    || { rm -rf "$repo_dir"; die "Cloning $REPO_URL failed (wrong URL, or no network?)."; }
fi

cd "$repo_dir" || die "Cannot enter $repo_dir"
[[ -f flake.nix ]] || die "No flake.nix in $repo_dir; this is not the dotfiles repo."

# --- 2. Host and theme ------------------------------------------------------

mapfile -t hosts < <(find hosts -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
# only a directory with a default.nix is a host
valid_hosts=()
for h in "${hosts[@]}"; do
  [[ -f "hosts/$h/default.nix" ]] && valid_hosts+=("$h")
done
hosts=("${valid_hosts[@]}")
(( ${#hosts[@]} )) || die "No hosts found in $repo_dir/hosts (each needs a default.nix)."

# Themes come from the `themes = [ ... ];` list in flake.nix.
mapfile -t themes < <(sed -n '/^\s*themes =/,/\];/ s/^\s*"\([^"]*\)".*/\1/p' flake.nix)
(( ${#themes[@]} )) || die "No themes found in the themes list of flake.nix."

echo
info "Which host is this machine?"
host="$(choose "Host: " "${hosts[@]}")"
echo
info "Which theme?"
theme="$(choose "Theme: " "${themes[@]}")"

host_dir="hosts/$host"
hw="$host_dir/hardware.nix"
[[ -f "$host_dir/default.nix" ]] || die "$host_dir/default.nix is missing."

# --- 2b. Whose machines: the vars, out of the repo -------------------------

[[ -f vars/vars.toml ]] || die "vars/vars.toml is missing from the repo (the template for the values)."
[[ -f modules/nixos/base/rebuild/vars.sh ]] || die "modules/nixos/base/rebuild/vars.sh is missing from the repo."

echo
info "Your values (docs/vars.md), saved root-only to $VARS_DIR/vars.toml:"
bash modules/nixos/base/rebuild/vars.sh vars/vars.toml "$VARS_DIR" "$host" \
  || die "Saving the values failed (see above)."

vars_content="$(sudo cat "$VARS_DIR/vars.toml")" \
  || die "Cannot read $VARS_DIR/vars.toml (it was not saved)."
yq -p toml . <<< "$vars_content" > /dev/null 2>&1 \
  || die "$VARS_DIR/vars.toml is not valid TOML; fix or delete it and run this again."

# a value that is absent or empty is as good as no value: stop before the build
vars_get() { yq -p toml ".$1 // \"\"" <<< "$vars_content"; }

[[ "$(vars_get placeholder)" != true ]] \
  || die "$VARS_DIR/vars.toml still has placeholder = true: the real values were not saved."

missing=()
for key in username email domain repo; do
  [[ -n "$(vars_get "$key")" ]] || missing+=("$key")
done
if [[ "$host" == beacon ]]; then
  for key in lan.address lan.gateway lan.subnet; do
    [[ -n "$(vars_get "$key")" ]] || missing+=("$key")
  done
fi
(( ${#missing[@]} == 0 )) \
  || die "Missing values in $VARS_DIR/vars.toml: ${missing[*]}. Set them (sudo edit that file) and run this again."

user="$(vars_get username)"
override=(--override-input vars "path:$VARS_DIR")

[[ "$user_name" == "$user" ]] || warn "You are '$user_name', but the config sets up the user '$user'."

# unfree.enable (on by default) lives in the host's default.nix
echo
snapshot="$(mktemp -d)"
cp -a "$host_dir/." "$snapshot/"
trap restore_host EXIT
sed -i '/^\s*unfree\.enable\s*=/d' "$host_dir/default.nix"
if confirm "Allow the unfree software in the repo (claude-code, MS Office fonts, Steam)? [Y/n]" y; then
  info "Unfree software allowed"
else
  insert_after_hostname "$host_dir/default.nix" "unfree.enable = false;"
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
  generated="$(sudo nixos-generate-config --show-hardware-config)" \
    || die "nixos-generate-config failed (see above); the hardware config is unchanged."
  grep -q 'fileSystems' <<< "$generated" \
    || die "nixos-generate-config found no file systems; not touching $hw."

  if is_generated "$hw"; then
    cp "$hw" "$hw.bak"
    info "Old config saved to $hw.bak (untracked)"
  elif [[ -f "$hw" ]] && ! grep -q 'PLACEHOLDER' "$hw"; then
    # keep hand tuning (e.g. anvil's) beside the generated file
    [[ ! -e "$host_dir/hardware-extra.nix" ]] \
      || die "$host_dir/hardware-extra.nix already exists; move it aside and run this again."
    grep -q '\./hardware\.nix' "$host_dir/default.nix" \
      || die "$host_dir/default.nix does not import ./hardware.nix, so hand-written settings cannot be kept."
    mv "$hw" "$host_dir/hardware-extra.nix"
    sed -i 's|\./hardware\.nix|./hardware.nix ./hardware-extra.nix|' "$host_dir/default.nix"
    git add "$host_dir/hardware-extra.nix"
    info "Kept hand-written settings as $host_dir/hardware-extra.nix"
  fi

  # a single LUKS device goes to encryption.nix (as cryptroot), not hardware.nix
  mapfile -t luks < <(grep -E '^\s*boot\.initrd\.luks\.devices\.' <<< "$generated" || true)
  sed -i '/^\s*encryption\.\(enable\|device\)\s*=/d' "$host_dir/default.nix"
  luks_dev=""
  luks_name=""
  if (( ${#luks[@]} == 1 )); then
    luks_dev="$(sed -n 's/.*\.device\s*=\s*"\([^"]*\)".*/\1/p' <<< "${luks[0]}")"
    luks_name="$(sed -n 's/.*luks\.devices\."\?\([^".]*\)"\?\.device.*/\1/p' <<< "${luks[0]}")"
  fi

  if [[ -n "$luks_dev" && -n "$luks_name" ]]; then
    generated="$(grep -vE '^\s*boot\.initrd\.luks\.devices\.' <<< "$generated")"
    # the module opens it as cryptroot, so the root fs must mount that
    generated="${generated//\/dev\/mapper\/$luks_name\"//dev/mapper/cryptroot\"}"
    insert_after_hostname "$host_dir/default.nix" "encryption.device = \"$luks_dev\";"
    info "LUKS root detected ($luks_dev), using the themed unlock prompt"
  else
    insert_after_hostname "$host_dir/default.nix" "encryption.enable = false;"
    if (( ${#luks[@]} > 1 )); then
      warn "Multiple LUKS devices found; left them in hardware.nix and disabled the encryption module."
    elif (( ${#luks[@]} == 1 )); then
      warn "Could not read the LUKS device from: ${luks[0]}; disabled the encryption module."
    else
      info "No LUKS detected, disabling the encryption module"
    fi
  fi

  printf '%s\n' "$generated" > "$hw" || die "Could not write $hw."
  info "Wrote $hw"
fi

# --- 4. Link /etc/nixos -----------------------------------------------------

if [[ "$(readlink /etc/nixos || true)" == "$repo_dir" ]]; then
  info "/etc/nixos already links to $repo_dir"
else
  if [[ -L /etc/nixos ]]; then
    sudo rm /etc/nixos || die "Could not remove the old /etc/nixos link."
  elif [[ -e /etc/nixos ]]; then
    backup="/etc/nixos.bak-$(date +%Y%m%d-%H%M%S)"
    sudo mv /etc/nixos "$backup" || die "Could not move the old /etc/nixos to $backup."
    info "Moved the old /etc/nixos to $backup"
  fi
  sudo ln -s "$repo_dir" /etc/nixos || die "Could not link /etc/nixos -> $repo_dir."
  info "Linked /etc/nixos -> $repo_dir"
fi

target="$host-$theme"

# a wrong host or theme shows up here, before a long build
sudo_nix eval "${override[@]}" "$repo_dir#nixosConfigurations.$target.config.networking.hostName" > /dev/null \
  || die "$target is not in the flake; check the hosts/ directory and the themes list in flake.nix (error above)."

echo
# switching live from the installer fails; install for the next boot
built=false
if confirm "Build $target and install it for the next boot? [Y/n]" y; then
  info "Building $target"
  # as root: the vars are root-only
  system="$(sudo_nix build --no-link --print-out-paths "${override[@]}" \
    "$repo_dir#nixosConfigurations.$target.config.system.build.toplevel")" \
    || die "Build of $target failed (error above). Fix it and run this script again."
  [[ -n "$system" && -x "$system/bin/switch-to-configuration" ]] \
    || die "The build did not give a system to install (got: '$system')."
  sudo env NIX_CONFIG="$NIX_CONFIG" nix-env -p /nix/var/nix/profiles/system --set "$system" \
    || die "Could not set the system profile to $system."
  sudo "$system/bin/switch-to-configuration" boot \
    || die "Installing $system for boot failed (error above). Run this script again to retry."
  info "Installed $system"
  built=true
else
  info "Later, run: sudo nixos-rebuild boot --flake /etc/nixos#$target ${override[*]}"
fi

# the edits are final from here on: a later failure must not undo them
snapshot=""

# keys, host secrets (rebuild.secrets) and ~/.pfp come from rebuild, not from here
secrets=()
# shellcheck disable=SC2016 # nix expression, not shell
if secrets_out="$(sudo_nix eval --raw "${override[@]}" "$repo_dir#nixosConfigurations.$target.config.rebuild.secrets" \
  --apply 's: builtins.concatStringsSep "\n" (map (p: "${p}: ${s.${p}.description}") (builtins.attrNames s))' \
  2> /dev/null)"; then
  while IFS= read -r line; do
    if [[ -n "$line" ]]; then
      secrets+=("$line")
    fi
  done <<< "$secrets_out"
else
  warn "Could not list the secrets of $target; rebuild will still ask for what it needs."
fi

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
  if confirm "Reboot now? [Y/n]" y; then
    sudo reboot
  else
    info "Reboot when you're ready to start $target."
  fi
fi
