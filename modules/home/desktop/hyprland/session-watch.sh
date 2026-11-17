# session-watch: stop graphical-session.target when Hyprland exits.
# The portal keeps it alive otherwise, so the next login skips waybar etc.
socket="${XDG_RUNTIME_DIR:?}/${WAYLAND_DISPLAY:?}"
pid="$(ss -xlpn src "$socket" | grep -o 'pid=[0-9]*' | head -n1 | cut -d= -f2)"
if [ -z "$pid" ]; then
  echo "session-watch: no process owns $socket" >&2
  exit 1
fi

# outside the compositor's process tree, so it outlives it
exec systemd-run --user --collect --quiet --unit="session-watch-$pid" \
  "$(command -v sh)" -c \
  "$(command -v tail) --pid=$pid -f /dev/null; $(command -v systemctl) --user stop graphical-session.target"
