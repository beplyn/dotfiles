# clipboard <command> <store> ...: cliphist for the quickshell clipboard
# panel. Two stores: "history", the db wl-paste fills, and "pinned", a cliphist
# db of its own so pins outlive the history's max-items and wipes.
#
#   list <store>               "<id>\t<preview>", newest first
#   copy <store> <id> [mime]   back onto the clipboard through wl-copy
#   text <store> <id>          the content, cut short for the preview pane
#   thumb <store> <id> <ext>   decode an image once, print its path
#   pin <store> <id>           copy an entry into the pins
#   delete <store> <id>
#   wipe <store>

pins="${XDG_DATA_HOME:-$HOME/.local/share}/cliphist/pins.db"
thumbs="${XDG_RUNTIME_DIR:-/tmp}/haku-clipboard"

store_history() {
  cliphist "$@"
}

store_pinned() {
  mkdir -p "$(dirname "$pins")"
  cliphist -db-path "$pins" -max-items 1000 "$@"
}

store="${2:-}"
case "$store" in
  history | pinned) ;;
  *)
    echo "clipboard: unknown store '$store' (history or pinned)" >&2
    exit 2
    ;;
esac

case "${1:-}" in
  list)
    "store_$store" -preview-width 400 list
    ;;
  copy)
    if [ -n "${4:-}" ]; then
      "store_$store" decode "$3" | wl-copy --type "$4"
    else
      "store_$store" decode "$3" | wl-copy
    fi
    ;;
  text)
    "store_$store" decode "$3" | head -c 20000
    ;;
  thumb)
    mkdir -p "$thumbs"
    file="$thumbs/$store-$3.$4"
    [ -s "$file" ] || "store_$store" decode "$3" > "$file"
    echo "$file"
    ;;
  pin)
    "store_$store" decode "$3" | store_pinned store
    ;;
  delete)
    echo "$3" | "store_$store" delete
    rm -f "$thumbs/$store-$3".*
    ;;
  wipe)
    "store_$store" wipe
    # ids start over after a wipe, so the cached images would be wrong
    rm -f "$thumbs/$store"-*
    ;;
  *)
    echo "usage: clipboard <list|copy|text|thumb|pin|delete|wipe> <history|pinned> ..." >&2
    exit 2
    ;;
esac
