# rebuild-gate: switch only to commits signed by the master key; an unsigned one needs a TOTP code
#   state                 deployed rev and missing host secrets       (sudo, no password)
#   deploy <theme> <rev>  git bundle of new commits on stdin, by rebuild (sudo, no password)
#   fetch                 the auto-deploy timer: signed only, never prompts
#   init                  enrol the TOTP seed, paste the master key    (sudo: password + TOTP)

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

# a nerd font glyph leads on a terminal only; the journal and pipes get the bare text
mark() {
  if [ -t 2 ]; then
    printf '\e[%sm%s\e[0m %s\n' "$1" "$2" "$3" >&2
  else
    printf '%s\n' "$3" >&2
  fi
}
say() { mark 34  "$*"; }
warn() { mark 33  "$*"; }
err() { mark 31  "$*"; }
if [ -t 2 ]; then
  key=$'\e[35m'""$'\e[0m '
  ask=$'\e[35m'""$'\e[0m '
fi

# read_hidden VAR PROMPT: like read -s, but a * per character; backspace takes one back
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

journal() {
  logger -t rebuild-gate -p auth.notice -- "$*" 2>/dev/null || true
}

log() {
  say "$*"
  journal "$*"
}

die() {
  err "$*"
  journal "$*"
  exit 1
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
    err "no TOTP seed at $seed; enrol one with: sudo rebuild-gate init"
    return 1
  fi
  if [ -e "$failed" ] && [ $(( $(date +%s) - $(stat -c %Y "$failed") )) -lt 60 ]; then
    warn "a TOTP code failed less than a minute ago, try again later"
    return 1
  fi
  read_hidden code "${key}TOTP code: " </dev/tty
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
  err "wrong or already used TOTP code"
  journal "wrong or already used TOTP code"
  return 1
}

# rest of a paste (a private key's body, a stray newline): not for the prompt or the shell
drain_tty() {
  while IFS= read -r -t 0.5 _; do :; done </dev/tty || true
}

# pasted into the terminal, beacon never sees the stick: one ssh-... line, or a whole armored block
read_paste() {
  local line
  IFS= read -r line || line=
  line="${line%$'\r'}"
  printf '%s\n' "$line"
  if [ "$line" = "-----BEGIN PGP PUBLIC KEY BLOCK-----" ]; then
    while IFS= read -r line; do
      line="${line%$'\r'}"
      printf '%s\n' "$line"
      [ "$line" = "-----END PGP PUBLIC KEY BLOCK-----" ] && break
    done
  fi
}

# the public half only: one SSH key, or one GPG key without secret parts
import_key() {
  local paste type blob rest line='' fpr answer
  install -d -m 0700 "@keysDir@" "$GNUPGHOME"
  paste="$(mktemp)"
  say "Paste the master public key: the ssh-... line from the .pub, or the whole PGP PUBLIC KEY BLOCK (empty to skip)."
  read_paste </dev/tty >"$paste"
  drain_tty

  read -r type blob rest <"$paste" || true
  if [ -z "$type" ]; then
    rm -f "$paste"
    return 1
  elif grep -q PRIVATE "$paste"; then
    err "that is a private key: it stays on the stick, paste the public one"
    rm -f "$paste"
    return 1
  elif [[ "$type" =~ ^(ssh-|ecdsa-|sk-) ]]; then
    line="master namespaces=\"git\" $type $blob"
    if ! fpr="$(ssh-keygen -l -f /dev/stdin <<<"$type $blob" 2>/dev/null)"; then
      err "not an SSH public key"
      rm -f "$paste"
      return 1
    fi
    say "SSH key: $fpr"
    say "compare with \`ssh-keygen -lf <key>.pub\` on the workstation"
  elif [ "$(gpg --show-keys --with-colons "$paste" 2>/dev/null | grep -c '^pub:')" -eq 1 ] \
      && ! gpg --show-keys --with-colons "$paste" 2>/dev/null | grep -q '^sec:'; then
    fpr="$(gpg --show-keys --with-colons "$paste" | awk -F: '$1 == "fpr" { print $10; exit }')"
    say "GPG key: $fpr ($(gpg --show-keys --with-colons "$paste" | awk -F: '$1 == "uid" { print $10; exit }'))"
    say "compare with \`gpg --fingerprint\` on the workstation"
  else
    err "neither one SSH public key nor one GPG public key"
    rm -f "$paste"
    return 1
  fi

  read -rp "${ask}Same fingerprint as on the workstation? [y/N] " answer </dev/tty || answer=
  if [[ "$answer" != [yY]* ]]; then
    rm -f "$paste"
    return 1
  fi
  if [ -n "$line" ]; then
    printf '%s\n' "$line" | install -m 0600 /dev/stdin "$signers"
  else
    gpg --batch --quiet --import "$paste"
    echo "$fpr:6:" | gpg --batch --quiet --import-ownertrust
  fi
  rm -f "$paste"
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
      warn "No master key on @hostName@ yet; importing one takes a TOTP code."
      if ! { totp_ok && import_key; }; then
        err "still no master key"
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
      warn "$(describe "$rev"): $why. A TOTP code deploys it anyway."
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
      say "@branch@ is at the deployed $rev"
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
    has_tty || die "init is interactive: ssh -t @hostName@ sudo rebuild-gate init"
    lock
    if [ -s "$seed" ]; then
      say "TOTP seed already at $seed (delete it to enrol a new one)"
    else
      say "Enrolling the TOTP seed: scan the QR code, then confirm a code."
      install -d -m 0700 "$(dirname "$seed")"
      google-authenticator -t -d -f -r 3 -R 30 -w 3 -e 5 \
        -l "@username@@@hostName@" -i "@hostName@" -s "$seed" </dev/tty
      chmod 0600 "$seed"
      warn "Keep the emergency scratch codes above offline; they work for sudo, not for the gate."
      log "TOTP seed enrolled"
    fi
    if have_key; then
      say "master key already imported (delete $signers or $GNUPGHOME to replace it)"
    else
      import_key || die "no master key imported"
    fi
    ;;

  *)
    die "usage: rebuild-gate state | deploy <theme> <rev> | fetch | init"
    ;;
esac
