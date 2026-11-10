# wallpaper set IMAGE | random | current
# Picks from the theme's recoloured set in @cache@ (quickshell/wallpaper.nix).
# current.jpg links the pick; hyprpaper, hyprlock and the greeter (rebuild)
# show it. Picks link the cache's name, not the store path, so a rebuild
# into another theme recolours the current one too.
cache="@cache@"
current="$cache/current.jpg"

usage() {
  echo "usage: wallpaper set IMAGE | random | current" >&2
}

apply() {
  ln -sfn "$1" "$current"
  # hyprpaper reads the link when it starts; this swaps it live. No session
  # (e.g. a TTY): the lock screen still follows the link
  @hyprctl@ hyprpaper wallpaper ",$(readlink -f "$current"),cover" >/dev/null 2>&1 || true
}

case "${1:-}" in
  set)
    if [ ! -e "${2:-}" ]; then
      echo "wallpaper: no such image: ${2:-}" >&2
      exit 1
    fi
    apply "$2"
    ;;
  random)
    # anything but the one showing, unless it is the only one
    now="$(readlink "$current" 2>/dev/null || true)"
    pick="$(find "$cache" -maxdepth 1 -name '*.jpg' ! -name current.jpg ! -path "$now" | shuf -n1)"
    pick="${pick:-$now}"
    if [ -z "$pick" ]; then
      echo "wallpaper: nothing in $cache" >&2
      exit 1
    fi
    apply "$pick"
    ;;
  current)
    readlink "$current" || true
    ;;
  *)
    usage
    exit 1
    ;;
esac
