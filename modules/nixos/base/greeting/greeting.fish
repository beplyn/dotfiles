function __greeting_age -a secs
  if test $secs -lt 3600
    echo (math -s0 $secs / 60)m
  else if test $secs -lt 86400
    echo (math -s0 $secs / 3600)h
  else
    echo (math -s0 $secs / 86400)d
  end
end

function __greeting
  set -l now (date +%s)
  set -l dot " $(set_color @muted@)·$(set_color normal) "

  # who, when, uptime
  set -l up (string split -f1 . < /proc/uptime)
  set -l h (math -s0 $up / 3600)
  set -l m (math -s0 $up % 3600 / 60)
  set -l uptime (test $h -gt 0; and echo "$h"h" $m"m; or echo "$m"m)
  echo "  $(set_color @blue@)$(set_color normal) $(set_color @purple@)$USER@$hostname$(set_color normal)$dot$(date '+%a %d %b  %H:%M' | string lower)$dot""up $uptime"

  # generation, flake.lock, dotfiles
  set -l parts
  set -l gen (string match -r '\d+' (path basename (readlink /nix/var/nix/profiles/system)))
  if test -n "$gen"
    set -l built (stat -c %Y /nix/var/nix/profiles/system-$gen-link)
    set -a parts "gen $gen (built $(__greeting_age (math $now - $built)) ago)"
  end
  set -l flake /etc/nixos
  test -d $flake; or set flake ~/dotfiles
  if test -d $flake/.git
    set -l locked (git -C $flake log -1 --format=%ct -- flake.lock 2>/dev/null)
    test -n "$locked"; and set -a parts "flake.lock $(__greeting_age (math $now - $locked)) old"
    set -l dirty (git -C $flake status --porcelain 2>/dev/null | count)
    if test $dirty -gt 0
      set -a parts "dotfiles: $(set_color @yellow@)$dirty uncommitted$(set_color normal)"
    else
      set -a parts "dotfiles: $(set_color @green@)clean$(set_color normal)"
    end
  end
  test (count $parts) -gt 0
  and echo "  $(set_color @cyan@)󱄅$(set_color normal)  $(string join -- $dot $parts)"

  # warnings, if any
  set -l warn
  set -l failed (systemctl --failed --no-legend --plain 2>/dev/null | string split -f1 ' ') \
    (systemctl --user --failed --no-legend --plain 2>/dev/null | string split -f1 ' ')
  set -l n (count $failed)
  test $n -eq 1; and set -a warn "1 failed unit: $failed"
  test $n -gt 1; and set -a warn "$n failed units: $(string join ', ' $failed)"
  for line in (df -l -x tmpfs -x devtmpfs -x efivarfs -x overlay --output=pcent,target 2>/dev/null | tail -n +2)
    set -l f (string split -n ' ' (string trim $line))
    set -l pct (string trim -c % $f[1])
    test $pct -ge @diskWarn@; and set -a warn "$f[2] at $pct%"
  end
  test (count $warn) -gt 0
  and echo "  $(set_color @red@)⚠$(set_color normal)  $(string join -- $dot $warn)"
end

# skip in nvim/yazi
if not set -q NVIM; and not set -q YAZI_LEVEL
  set -l marker $XDG_RUNTIME_DIR/fish-greeted
  if set -q SSH_CONNECTION; or not test -e $marker; or test (random 1 @chance@) -eq 1
    touch $marker 2>/dev/null
    __greeting
  end
end
