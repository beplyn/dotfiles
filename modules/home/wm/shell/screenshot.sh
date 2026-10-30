mode="${1:-area}"
dir="$HOME/Pictures/Screenshots"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
mkdir -p "$dir"

case "$mode" in
  area)
    geometry="$(slurp -d \
      -b '@background@66' \
      -c '@accent@ff' \
      -s '@accent@22' \
      -B '@background@00' \
      -w 2)" || exit 0
    grim -g "$geometry" "$file"
    ;;
  output)
    output="$(niri msg --json focused-output | jq -r '.name')"
    grim -o "$output" "$file"
    ;;
  *)
    echo "usage: screenshot [area|output]" >&2
    exit 1
    ;;
esac

wl-copy --type image/png < "$file"

action="$(notify-send \
  --app-name=Screenshot \
  --icon="$file" \
  --hint="string:image-path:$file" \
  --action=edit=Edit \
  --action=open=Open \
  --action=folder=Folder \
  --wait \
  "Screenshot saved" \
  "$(basename "$file") · copied to clipboard")" || exit 0

case "$action" in
  edit) satty --filename "$file" --output-filename "$file" ;;
  open) xdg-open "$file" ;;
  folder) xdg-open "$dir" ;;
esac
