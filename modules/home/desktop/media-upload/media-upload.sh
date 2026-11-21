# ~/Music, ~/Videos -> beacon's libraries; never deletes there
sock="${XDG_RUNTIME_DIR:-/tmp}/media-upload-%C"
# one connection, so one TOTP prompt
ssh="ssh -p $BEACON_PORT -o ControlMaster=auto -o ControlPath=$sock -o ControlPersist=60"

for pair in "$HOME/Music:music" "$HOME/Videos:video"
do
  src="${pair%%:*}"
  dst="${pair##*:}"
  [[ -d $src ]] || continue
  echo "$src -> $dst"
  # readable by navidrome and jellyfin
  rsync -rt --chmod=D755,F644 --info=progress2 -h -e "$ssh" \
    "$src/" "$BEACON_HOST:$BEACON_BULK/$dst/"
done
