# eap-connect.sh <ssid>: join WPA-Enterprise (PEAP + MSCHAPv2, no CA, e.g. eduroam).
# Credentials come in EAP_IDENTITY / EAP_PASSWORD to keep them out of argv.

ssid=$1

nmcli connection add type wifi con-name "$ssid" ssid "$ssid" \
  wifi-sec.key-mgmt wpa-eap \
  802-1x.eap peap \
  802-1x.phase2-auth mschapv2 \
  802-1x.identity "$EAP_IDENTITY" \
  802-1x.password-flags 0 >/dev/null

# save the secrets (flags 0 = system owned); nmcli's agent needs the identity too
if ! printf '802-1x.identity:%s\n802-1x.password:%s\n' "$EAP_IDENTITY" "$EAP_PASSWORD" \
  | nmcli --wait 45 connection up id "$ssid" passwd-file /dev/stdin >/dev/null
then
  # Drop the half-made profile so the network isn't "Saved" with no password.
  nmcli connection delete id "$ssid" >/dev/null 2>&1 || true
  exit 1
fi
