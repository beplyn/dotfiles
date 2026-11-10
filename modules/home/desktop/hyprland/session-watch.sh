# session-watch: once Hyprland, the owner of this session's Wayland socket,
# exits, crash or not, stop graphical-session.target.
# xdg-desktop-portal's Requisite= keeps that target "needed", so it outlives
# Hyprland; the next login then finds it active and never starts waybar,
# quickshell and co.
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
