# openrgb-stylix: paint every device the OpenRGB server found in one colour.
# Static where a device has it, so it sticks in hardware; Direct or Custom
# (per-LED, e.g. the Red Devil GPU) otherwise.
# --nodetect: only talk to the local server (port 6742), never probe hardware
colour="${1:?usage: openrgb-stylix RRGGBB}"

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
while read -r line; do
  case $line in
    [0-9]*:\ *) dev="${line%%:*}" ;;
    Modes:*)
      # "Modes: Direct [Static] 'Color Cycle' ..." -> " direct static color cycle ... "
      modes=" ${line#Modes:} "
      modes="${modes//[\[\]\']/}"
      modes="${modes,,}"
      if [[ $modes == *" static "* ]]; then
        args+=(--device "$dev" --mode static --color "$colour")
      elif [[ $modes == *" direct "* ]]; then
        args+=(--device "$dev" --mode direct --color "$colour")
      elif [[ $modes == *" custom "* ]]; then
        args+=(--device "$dev" --mode custom --color "$colour")
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

# 1.0 keeps profiles on the server; the GUI loads this one at login. Saved in
# the same run: on its own --save-profile reapplies every device's mode
# without a colour and fails
exec openrgb --nodetect "${args[@]}" --save-profile stylix
