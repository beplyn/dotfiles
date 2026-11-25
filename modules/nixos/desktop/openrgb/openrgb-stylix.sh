# openrgb-stylix: paint every device, keyboards in their own colour.
# Static if possible (sticks in hardware), else Direct/Custom; the GPU follows
# the motherboard. Keyboards go Direct first (Everest ignores Static).
# --nodetect: only talk to the local server, never probe hardware
colour="${1:?usage: openrgb-stylix RRGGBB [KEYBOARD_RRGGBB]}"
keyboard_colour="${2:-$colour}"

# the server answers before detection is done; wait for devices
list=""
for _ in $(seq 60); do
  # 1.0 only prints the modes in the detailed list
  list="$(openrgb --nodetect --list-detailed 2>/dev/null || true)"
  if grep -q '^[0-9]*: ' <<<"$list"; then
    break
  fi
  sleep 2
done

args=()
dev=""
type=""
while read -r line; do
  case $line in
    [0-9]*:\ *) dev="${line%%:*}" ;;
    Type:*) type="${line#Type:}"; type="${type// /}" ;;
    Modes:*)
            # mode names from openrgb's list, lowercased
      modes=" ${line#Modes:} "
      modes="${modes//[\[\]\']/}"
      modes="${modes,,}"
      c=$colour
      [[ $type == Keyboard ]] && c=$keyboard_colour
      if [[ $modes == *" sync with motherboard "* ]]; then
        args+=(--device "$dev" --mode "sync with motherboard")
      elif [[ $type == Keyboard && $modes == *" direct "* ]]; then
        args+=(--device "$dev" --mode direct --color "$c")
      elif [[ $modes == *" static "* ]]; then
        args+=(--device "$dev" --mode static --color "$c")
      elif [[ $modes == *" direct "* ]]; then
        args+=(--device "$dev" --mode direct --color "$c")
      elif [[ $modes == *" custom "* ]]; then
        args+=(--device "$dev" --mode custom --color "$c")
      else
        echo "openrgb-stylix: device $dev has no Static, Direct or Custom, skipped" >&2
      fi
      ;;
  esac
done <<<"$list"

if [ "${#args[@]}" -eq 0 ]; then
  echo "openrgb-stylix: no devices to paint" >&2
  exit 0
fi

# the GUI loads this profile at login; save it in the same run or it fails
exec openrgb --nodetect "${args[@]}" --save-profile stylix
