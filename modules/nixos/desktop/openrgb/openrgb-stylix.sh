# openrgb-stylix: paint every device the OpenRGB server found in one colour.
# Static where a device has it, so it sticks in hardware; Direct otherwise.
# --nodetect: only talk to the local server (port 6742), never probe hardware
colour="${1:?usage: openrgb-stylix RRGGBB}"

# the server answers before detection is done; wait for devices
list=""
for _ in $(seq 60); do
  list="$(openrgb --nodetect --list-devices 2>/dev/null || true)"
  if grep -q '^[0-9]*: ' <<<"$list"; then
    break
  fi
  sleep 2
done

args=()
dev=""
while read -r line; do
  case $line in
    [0-9]*:\ *) dev="${line%%:*}" ;;
    Modes:*)
      modes=" ${line#Modes:} "
      modes="${modes//[\[\]]/}"
      modes="${modes,,}"
      if [[ $modes == *" static "* ]]; then
        args+=(--device "$dev" --mode static --color "$colour")
      elif [[ $modes == *" direct "* ]]; then
        args+=(--device "$dev" --mode direct --color "$colour")
      else
        echo "openrgb-stylix: device $dev has neither Static nor Direct, skipped" >&2
      fi
      ;;
  esac
done <<<"$list"

if [ "${#args[@]}" -eq 0 ]; then
  echo "openrgb-stylix: no devices to paint" >&2
  exit 0
fi
exec openrgb --nodetect "${args[@]}"
