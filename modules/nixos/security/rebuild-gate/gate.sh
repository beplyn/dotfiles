# rebuild-gate: switch only to commits signed by the master key; an unsigned one needs a TOTP code
#   state                 deployed rev and missing host secrets       (sudo, no password)
#   deploy <theme> <rev>  git bundle of new commits on stdin, by rebuild (sudo, no password)
#   fetch                 the auto-deploy timer: signed only, never prompts
#   init                  enrol the TOTP seed, import the master key   (sudo: password + TOTP)

# nothing from the caller: not its PATH, not its git config
export PATH="@path@"
export HOME=/root
export GIT_CONFIG_GLOBAL=/dev/null
export GNUPGHOME="@keysDir@/gnupg"
unset SUDO_UID SUDO_GID
umask 077

signers="@keysDir@/allowed_signers"
remote="@remote@"
seed="@totpSecret@"
repo="@stateDir@/repo"
deployed=refs/heads/deployed
themes=(@themes@)
secrets=(@secrets@)
totpDone=

die() {
  log "$*"
  exit 1
}

log() {
  echo "$*" >&2
  logger -t rebuild-gate -p auth.notice -- "$*" 2>/dev/null || true
}

has_tty() {
  { : </dev/tty; } 2>/dev/null
}

ensure_repo() {
  if [ ! -d "$repo" ]; then
    git init -q --bare "$repo"
    git -C "$repo" symbolic-ref HEAD "$deployed"
  fi
}

have_key() {
  [ -s "$signers" ] || [ -s "$GNUPGHOME/pubring.kbx" ]
}

describe() {
  git -C "$repo" -c gpg.ssh.allowedSignersFile="$signers" log -1 --format='%h "%s" (signature %G?, key %GK)' "$1" 2>/dev/null
}

# G only: good and from the one key the gate holds (listed for SSH, ultimately trusted for GPG)
signed() {
  local status
  status="$(git -C "$repo" -c gpg.ssh.allowedSignersFile="$signers" log -1 --format=%G? "$1" 2>/dev/null || true)"
  [ "$status" = G ]
}

# no rollbacks: a new commit has to build on the deployed one
ahead() {
  ! git -C "$repo" rev-parse -q --verify "$deployed" >/dev/null \
    || git -C "$repo" merge-base --is-ancestor "$deployed" "$1"
}

# one code per run, one failure a minute, a time step is never accepted twice
totp_ok() {
  local code secret now off step last=0 used="@keysDir@/totp-step" failed="@keysDir@/totp-failed"
  [ -n "$totpDone" ] && return
  if [ ! -s "$seed" ]; then
    echo "no TOTP seed at $seed; enrol one with: sudo rebuild-gate init" >&2
    return 1
  fi
  if [ -e "$failed" ] && [ $(( $(date +%s) - $(stat -c %Y "$failed") )) -lt 60 ]; then
    echo "a TOTP code failed less than a minute ago, try again later" >&2
    return 1
  fi
  read -rsp "TOTP code: " code </dev/tty || code=
  echo >&2
  secret="$(head -n1 "$seed")"
  now="$(date +%s)"
  [ -s "$used" ] && last="$(cat "$used")"
  if [[ "$code" =~ ^[0-9]{6}$ ]]; then
    for off in -30 0 30; do
      step=$(( (now + off) / 30 ))
      # key on stdin, never in argv
      if [ "$step" -gt "$last" ] \
          && [ "$(printf '%s' "$secret" | oathtool --totp -b -N "@$(( now + off ))" -)" = "$code" ]; then
        echo "$step" >"$used"
        rm -f "$failed"
        totpDone=1
        return
      fi
    done
  fi
  touch "$failed"
  log "wrong or already used TOTP code"
  return 1
}

# the public half only: one SSH key line, or one GPG key without secret parts
import_key() {
  local file type blob rest line fpr answer
  read -erp "Master public key file, absolute path (e.g. on the USB stick; empty to skip): " file </dev/tty || file=
  [ -n "$file" ] || return 1
  if [ ! -f "$file" ] || [ ! -r "$file" ]; then
    echo "$file is not a readable file" >&2
    return 1
  fi
  install -d -m 0700 "@keysDir@" "$GNUPGHOME"

  read -r type blob rest <"$file" || true
  if [[ "$type" =~ ^(ssh-|ecdsa-|sk-) ]]; then
    line="master namespaces=\"git\" $type $blob"
    if ! fpr="$(ssh-keygen -l -f /dev/stdin <<<"$type $blob" 2>/dev/null)"; then
      echo "$file is not an SSH public key" >&2
      return 1
    fi
    echo "SSH key: $fpr"
  elif [ "$(gpg --show-keys --with-colons "$file" 2>/dev/null | grep -c '^pub:')" -eq 1 ] \
      && ! gpg --show-keys --with-colons "$file" 2>/dev/null | grep -q '^sec:'; then
    fpr="$(gpg --show-keys --with-colons "$file" | awk -F: '$1 == "fpr" { print $10; exit }')"
    echo "GPG key: $fpr"
  else
    echo "$file is neither one SSH public key nor one GPG public key" >&2
    return 1
  fi

  read -rp "Same fingerprint as on the stick's machine? [y/N] " answer </dev/tty || answer=
  [[ "$answer" == [yY]* ]] || return 1
  if [ -n "${line:-}" ]; then
    printf '%s\n' "$line" | install -m 0600 /dev/stdin "$signers"
  else
    gpg --batch --quiet --import "$file"
    echo "$fpr:6:" | gpg --batch --quiet --import-ownertrust
  fi
  log "master key imported: $fpr"
}

switch() {
  local rev="$1" theme="$2"
  nixos-rebuild switch --flake "git+file://$repo?rev=$rev#@hostName@-$theme"
  git -C "$repo" update-ref "$deployed" "$rev"
  git -C "$repo" update-ref -d refs/gate/incoming 2>/dev/null || true
}

lock() {
  exec 9>/run/rebuild-gate.lock
  flock -n 9 || die "another rebuild-gate is running"
}

[ "$(id -u)" -eq 0 ] || die "rebuild-gate runs as root: sudo rebuild-gate ..."

case "${1:-}" in
  state)
    [ $# -eq 1 ] || die "usage: rebuild-gate state"
    if [ -d "$repo" ] && rev="$(git -C "$repo" rev-parse -q --verify "$deployed")"; then
      echo "deployed $rev"
    fi
    for path in "${secrets[@]}"; do
      [ -s "$path" ] || echo "missing $path"
    done
    ;;

  deploy)
    [ $# -eq 3 ] || die "usage: rebuild-gate deploy <theme> <rev> <bundle"
    theme="$2" rev="$3"
    [[ " ${themes[*]} " == *" $theme "* ]] || die "unknown theme $theme"
    [[ "$rev" =~ ^[0-9a-f]{40}$ ]] || die "not a commit id: $rev"
    has_tty || die "deploy is interactive; the timer runs fetch"
    lock
    ensure_repo

    # the commits the gate lacks; empty when it already has them
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cat >"$tmp/in.bundle"
    if [ -s "$tmp/in.bundle" ]; then
      git -C "$repo" bundle verify -q "$tmp/in.bundle" >/dev/null 2>&1 \
        || die "not a git bundle, or it builds on commits the gate doesn't have"
      git -C "$repo" fetch -q --no-tags "$tmp/in.bundle" "+HEAD:refs/gate/incoming"
    fi
    git -C "$repo" cat-file -e "$rev^{commit}" 2>/dev/null || die "$rev never reached the gate"

    if ! have_key; then
      echo "No master key on @hostName@ yet; importing one takes a TOTP code." >&2
      if ! { totp_ok && import_key; }; then
        echo "still no master key" >&2
      fi
    fi

    if signed "$rev" && ahead "$rev"; then
      log "deploying $(describe "$rev"), signed by the master key"
    else
      if signed "$rev"; then
        why="signed, but does not build on the deployed commit"
      else
        why="not signed by the master key"
      fi
      echo "$(describe "$rev"): $why. A TOTP code deploys it anyway." >&2
      totp_ok || die "not deploying $rev"
      log "deploying $(describe "$rev") on a TOTP code ($why)"
    fi
    switch "$rev" "$theme"
    ;;

  fetch)
    [ $# -eq 1 ] || die "usage: rebuild-gate fetch"
    [ -n "$remote" ] || die "no remote set (rebuildGate.autoDeploy.remote)"
    lock
    ensure_repo
    git -C "$repo" fetch -q --no-tags "$remote" "+refs/heads/@branch@:refs/remotes/origin/@branch@"
    rev="$(git -C "$repo" rev-parse "refs/remotes/origin/@branch@")"
    if [ "$rev" = "$(git -C "$repo" rev-parse -q --verify "$deployed" || true)" ]; then
      echo "@branch@ is at the deployed $rev"
      exit 0
    fi
    have_key || die "no master key; import it with: sudo rebuild-gate init"
    signed "$rev" || die "$(describe "$rev") is not signed by the master key, not deploying"
    ahead "$rev" || die "$(describe "$rev") does not build on the deployed commit, not deploying"
    log "deploying $(describe "$rev") from @branch@, signed by the master key"
    switch "$rev" "@themeName@"
    ;;

  init)
    [ $# -eq 1 ] || die "usage: sudo rebuild-gate init"
    has_tty || die "init is interactive"
    lock
    if [ -s "$seed" ]; then
      echo "TOTP seed already at $seed (delete it to enrol a new one)"
    else
      echo "Enrolling the TOTP seed: scan the QR code, then confirm a code."
      install -d -m 0700 "$(dirname "$seed")"
      google-authenticator -t -d -f -r 3 -R 30 -w 3 -e 5 \
        -l "@username@@@hostName@" -i "@hostName@" -s "$seed" </dev/tty
      chmod 0600 "$seed"
      echo "Keep the emergency scratch codes above offline; they work for sudo, not for the gate."
      log "TOTP seed enrolled"
    fi
    if have_key; then
      echo "master key already imported (delete $signers or $GNUPGHOME to replace it)"
    else
      import_key || die "no master key imported"
    fi
    ;;

  *)
    die "usage: rebuild-gate state | deploy <theme> <rev> | fetch | init"
    ;;
esac
