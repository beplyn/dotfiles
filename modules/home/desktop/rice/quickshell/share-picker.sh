# xdph share picker: quickshell asks, answers down a fifo.
# Prints "[SELECTION]<flags>/<choice>", nothing on cancel.
# Repeats within seconds (Chromium, Discord) reuse the first answer.

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/haku-share-picker"
CACHE="$STATE_DIR/last"
REUSE_SECONDS=8

mkdir -p "$STATE_DIR"

if [[ -f $CACHE ]] && (( $(date +%s) - $(stat -c %Y "$CACHE") < REUSE_SECONDS )); then
  selection=$(cat "$CACHE")
else
  fifo="$STATE_DIR/reply.$$"
  mkfifo "$fifo"
  trap 'rm -f "$fifo"' EXIT

  qs -c haku ipc call sharepicker pick "$fifo" "${XDPH_WINDOW_SHARING_LIST:-}" > /dev/null || exit 1
  # xdph waits on us; give up if the shell never answers
  selection=$(timeout 300 cat "$fifo") || exit 1
  # a cancel is reused too, or the next session would ask again
  printf '%s' "$selection" > "$CACHE"
fi

[[ -n $selection ]] || exit 1
printf '[SELECTION]%s\n' "$selection"
