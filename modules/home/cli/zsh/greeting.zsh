# greeting, as fish's: first shell per login, over ssh, else 1 in @chance@
# a cfonts banner rolls on its own, 1 in @bannerChance@; the fish one shares the marker, so only one shell greets

__greeting_age()
{
  local secs=$1
  if (( secs < 3600 )); then
    print -- "$(( secs / 60 ))m"
  elif (( secs < 86400 )); then
    print -- "$(( secs / 3600 ))h"
  else
    print -- "$(( secs / 86400 ))d"
  fi
}

# 24-bit foreground from a palette hex without the '#'
__greeting_fg()
{
  printf '\e[38;2;%d;%d;%dm' $(( 0x${1:0:2} )) $(( 0x${1:2:2} )) $(( 0x${1:4:2} ))
}

# the parts joined by the grey dot; $dot is the caller's
__greeting_join()
{
  local line=$1 part
  shift
  for part in "$@"; do
    line+="$dot$part"
  done
  print -r -- "$line"
}

__greeting()
{
  local reset=$'\e[0m'
  local nix_icon=$'\U000F1105'
  local warn_icon=$''
  local dot=" $(__greeting_fg @muted@)·$reset "
  local now=$(date +%s)

  # who, when, uptime
  local up h m uptime
  read -r up _ < /proc/uptime
  up=${up%%.*}
  h=$(( up / 3600 ))
  m=$(( up % 3600 / 60 ))
  if (( h > 0 )); then uptime="${h}h ${m}m"; else uptime="${m}m"; fi
  print -- "  $(__greeting_fg @blue@)$reset $(__greeting_fg @purple@)$USER@$HOST$reset$dot${(L)$(date '+%a %d %b  %H:%M')}$dot""up $uptime"

  # generation, flake.lock, dotfiles
  local -a parts=()
  local target gen built
  target=$(readlink /nix/var/nix/profiles/system)
  gen=${${target:t}//[^0-9]/}
  if [[ -n $gen ]]; then
    built=$(stat -c %Y /nix/var/nix/profiles/system-$gen-link)
    parts+=("gen $gen (built $(__greeting_age $(( now - built ))) ago)")
  fi
  # auto-rebuild hosts: when someone last switched by hand
  if [[ -d /var/lib/auto-rebuild ]]; then
    local manual=$(stat -c %Y /var/lib/rebuild/manual 2>/dev/null)
    if [[ -n $manual ]]; then
      parts+=("manual $(__greeting_age $(( now - manual ))) ago")
    else
      parts+=("manual never")
    fi
  fi
  local flake=/etc/nixos
  [[ -d $flake ]] || flake=~/dotfiles
  if [[ -d $flake/.git ]]; then
    local locked=$(git -C $flake log -1 --format=%ct -- flake.lock 2>/dev/null)
    [[ -n $locked ]] && parts+=("flake.lock $(__greeting_age $(( now - locked ))) old")
    local dirty=$(git -C $flake status --porcelain 2>/dev/null | wc -l)
    if (( dirty > 0 )); then
      parts+=("dotfiles: $(__greeting_fg @yellow@)$dirty uncommitted$reset")
    else
      parts+=("dotfiles: $(__greeting_fg @green@)clean$reset")
    fi
  fi
  if (( ${#parts} )); then
    print -- "  $(__greeting_fg @cyan@)$nix_icon$reset  $(__greeting_join "${parts[@]}")"
  fi

  # warnings, if any
  local -a failed=() warn=()
  failed=(${(f)"$(systemctl --failed --no-legend --plain 2>/dev/null)"} ${(f)"$(systemctl --user --failed --no-legend --plain 2>/dev/null)"})
  failed=(${${failed%% *}:#})
  local n=${#failed}
  (( n == 1 )) && warn+=("1 failed unit: $failed")
  (( n > 1 )) && warn+=("$n failed units: ${(j:, :)failed}")
  local pct where
  while read -r pct where; do
    pct=${pct%\%}
    (( pct >= @diskWarn@ )) && warn+=("$where at $pct%")
  done < <(df -l -x tmpfs -x devtmpfs -x efivarfs -x overlay --output=pcent,target 2>/dev/null | tail -n +2)
  if (( ${#warn} )); then
    print -- "  $(__greeting_fg @red@)$warn_icon$reset  $(__greeting_join "${warn[@]}")"
  fi
}

# skip in nvim/yazi; the banner only rolls when the fetch doesn't show
if [[ -z ${NVIM-} && -z ${YAZI_LEVEL-} ]]; then
  marker=$XDG_RUNTIME_DIR/fish-greeted
  if [[ -n ${SSH_CONNECTION-} || ! -e $marker || $(( RANDOM % @chance@ )) -eq 0 ]]; then
    touch $marker 2>/dev/null
    __greeting
  elif (( RANDOM % @bannerChance@ == 0 )); then
    fonts=(block simpleBlock simple 3d simple3d chrome shade slick grid pallet tiny)
    @cfonts@ "nix btw" -f ${fonts[RANDOM % ${#fonts} + 1]} -g "#@accent@,#@blue@"
  fi
fi
