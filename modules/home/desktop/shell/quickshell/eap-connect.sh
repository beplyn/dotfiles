# WPA-Enterprise join for the control center: eap-connect.sh <ssid>.
# Identity and password come via EAP_IDENTITY / EAP_PASSWORD so they never land
# in argv (world readable in /proc); printf is a builtin, so the pipe is safe too.
# PEAP + MSCHAPv2 without a CA cert covers eduroam and most campus/office setups.

ssid=$1

nmcli connection add type wifi con-name "$ssid" ssid "$ssid" \
  wifi-sec.key-mgmt wpa-eap \
  802-1x.eap peap \
  802-1x.phase2-auth mschapv2 \
  802-1x.identity "$EAP_IDENTITY" \
  802-1x.password-flags 0 >/dev/null

# Secrets handed over at activation get saved, since password-flags 0 is system owned.
# nmcli's agent asks for the identity too and fails the whole request without it.
if ! printf '802-1x.identity:%s\n802-1x.password:%s\n' "$EAP_IDENTITY" "$EAP_PASSWORD" \
  | nmcli --wait 45 connection up id "$ssid" passwd-file /dev/stdin >/dev/null
then
  # Drop the half-made profile so the network isn't "Saved" with no password.
  nmcli connection delete id "$ssid" >/dev/null 2>&1 || true
  exit 1
fi
