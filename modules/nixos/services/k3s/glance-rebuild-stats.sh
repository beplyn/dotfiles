dir=@dir@
install -d -m 0755 "$dir"
install -m 0644 @themeFile@ "$dir/theme.yml"

# the profile is already switched when activation scripts run
gen_of() { basename "$1" | sed -E 's/^system-([0-9]+)-link$/\1/'; }
fmt() { date -d "@$1" '+%Y-%m-%d %H:%M'; }

link=$(readlink /nix/var/nix/profiles/system)
gen=$(gen_of "$link")
built=$(fmt "$(stat -c %Y "/nix/var/nix/profiles/$link")")

history=$(for l in /nix/var/nix/profiles/system-*-link; do
  printf '%s\t%s\n' "$(gen_of "$l")" "$(fmt "$(stat -c %Y "$l")")"
done | sort -rn | head -n 5 | jq -Rs \
  'split("\n") | map(select(length > 0) | split("\t") | {generation: (.[0] | tonumber), built: .[1]})')

# the repo is owned by the user, not root
repo=/etc/nixos
commit=$(git -c safe.directory='*' -C "$repo" rev-parse --short HEAD 2>/dev/null || echo unknown)
message=$(git -c safe.directory='*' -C "$repo" log -1 --format=%s 2>/dev/null || echo unknown)

jq -n \
  --argjson generation "$gen" \
  --arg built "$built" \
  --arg commit "$commit" \
  --arg message "$message" \
  --arg release "@release@" \
  --arg kernel "$(uname -r)" \
  --arg theme "@theme@" \
  --argjson history "$history" \
  '{generation: $generation, built: $built, commit: $commit, message: $message,
    release: $release, kernel: $kernel, theme: $theme, history: $history}' \
  > "$dir/rebuild-stats.json.tmp"
chmod 0644 "$dir/rebuild-stats.json.tmp"
mv "$dir/rebuild-stats.json.tmp" "$dir/rebuild-stats.json"
