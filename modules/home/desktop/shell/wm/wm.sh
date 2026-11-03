# wm name | focused-output | dpms on|off
# Sockets, not just variables: sway leaves a stale SWAYSOCK in the systemd
# environment after it exits. hyprctl and mmsg come from PATH, with their
# compositor.
name()
{
  if [ -S "${NIRI_SOCKET:-}" ]; then
    echo niri
  elif [ -S "${SWAYSOCK:-}" ]; then
    echo sway
  elif [ -S "${XDG_RUNTIME_DIR:-}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket.sock" ]; then
    echo hyprland
  elif [ -S "${MANGO_INSTANCE_SIGNATURE:-}" ]; then
    echo mango
  # river sets nothing; classic (0.3) still has its status protocol, 0.4
  # leaves workspaces to its window manager and counts as generic
  elif wayland-info -i zriver_status_manager_v1 2>/dev/null | grep zriver_status_manager_v1 >/dev/null; then
    echo river
  else
    echo generic
  fi
}

focused_output()
{
  case "$(name)" in
    niri) niri msg --json focused-output | jq -r '.name' ;;
    sway) swaymsg -t get_outputs | jq -r '.[] | select(.focused).name' ;;
    hyprland) hyprctl -j monitors | jq -r '.[] | select(.focused).name' ;;
    mango) mmsg get all-monitors | jq -r '.monitors[] | select(.active).name' ;;
    *)
      # no protocol for focus: the only output, else pick one
      outputs="$(wlr-randr --json 2>/dev/null | jq -r '.[] | select(.enabled).name' || true)"
      if [ "$(printf '%s\n' "$outputs" | grep -c .)" = 1 ]; then
        echo "$outputs"
      else
        slurp -o -f '%o'
      fi
      ;;
  esac
}

dpms()
{
  case "$(name)" in
    niri) niri msg action "power-$1-monitors" ;;
    sway) swaymsg "output * power $1" ;;
    hyprland) hyprctl dispatch dpms "$1" ;;
    *) wlopm "--$1" '*' ;;
  esac
}

case "${1:-}" in
  name) name ;;
  focused-output) focused_output ;;
  dpms)
    case "${2:-}" in
      on | off) dpms "$2" ;;
      *) echo "usage: wm dpms on|off" >&2; exit 1 ;;
    esac
    ;;
  *)
    echo "usage: wm name | focused-output | dpms on|off" >&2
    exit 1
    ;;
esac
