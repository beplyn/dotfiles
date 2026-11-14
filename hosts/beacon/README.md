# beacon

Headless home server: k3s apps behind nginx and Cloudflare, see `default.nix`.

## Disks

All matched by filesystem label, so `sdX` letters shifting between boots can't swap them.
Every disk but the system SSD is `nofail`: beacon still boots without one, and the apps or
backups that need it fail instead of writing onto the system SSD.

| Disk                    | Label     | Mount          | Holds                                              |
|-------------------------|-----------|----------------|----------------------------------------------------|
| sdc Kingston 480G SSD   | (system)  | `/`            | OS, k3s, app state and databases (`/srv/apps`)    |
| sdb WD Green 120G SSD   | `cache`   | `/srv/cache`   | thumbnails, metadata, ML models: all regenerable   |
| sda Barracuda 2T HDD    | `scratch` | `/srv/scratch` | transcodes, encoded video: write-heavy, throwaway  |
| ST6000NM0034 6T HDD     | `tank`    | `/srv/tank`    | music, video, photos, documents, notes, books, sync (btrfs subvolumes) |
| ST6000NM0034 6T HDD     | `backup`  | `/srv/backup`  | `tank/` from btrbk, `k3s-state/` from k3s-backup  |

tank and backup are single-disk btrfs, scrubbed monthly. A scrub finds rotten data on either
one but can only repair metadata (kept twice); the good copy of rotten data is on the other disk.

## Backups

- **btrbk-tank** (daily): read-only snapshots of every tank subvolume in `/srv/tank/.btrbk`
  (kept 14 days), sent incrementally to `/srv/backup/tank` (kept 14 daily, 8 weekly,
  6 monthly). Video is included, so deleted video holds space on the backup disk for 6 months.
- **k3s-backup** (03:30): `/srv/apps` with live sqlite copied through `.backup`, `pg_dumpall`
  of every postgres, and the cluster itself (its sqlite datastore, join token, every Secret
  including the sealed-secrets key), into `/srv/backup/k3s-state/<date>` (kept 14 days).
- Either one failing pushes its log to ntfy's `alerts` topic.

Both are on the same machine as the data: they cover deleted files, bad edits and a dead disk,
not a fire or theft.

## First deploy

1. Run `rebuild` on beacon. The disks are `nofail`, so this is safe before they exist.
2. Format the disks. **This erases them.** Check with
   `lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,LABEL`: the two 6T disks are the same model, so
   pick tank and backup by serial and use their `/dev/disk/by-id/` paths.

   ```sh
   sudo wipefs -a /dev/disk/by-id/<tank-disk> /dev/disk/by-id/<backup-disk> /dev/sdb /dev/sda
   sudo mkfs.btrfs -L tank -d single -m dup /dev/disk/by-id/<tank-disk>
   sudo mkfs.btrfs -L backup -d single -m dup /dev/disk/by-id/<backup-disk>
   sudo mkfs.ext4 -L cache /dev/sdb
   sudo mkfs.ext4 -L scratch /dev/sda
   sudo systemctl start srv-tank.mount srv-backup.mount srv-cache.mount srv-scratch.mount
   sudo systemctl restart k3s-app-dirs
   ```

   `k3s-app-dirs` makes the tank subvolumes and app directories; the pods start on their next retry.

   Already made the old raid1 `tank` and put data on it? Split it without losing anything:

   ```sh
   sudo btrfs balance start -dconvert=single -mconvert=dup /srv/tank
   sudo btrfs device remove /dev/disk/by-id/<backup-disk> /srv/tank
   sudo mkfs.btrfs -f -L backup -d single -m dup /dev/disk/by-id/<backup-disk>
   ```

3. Point the router's DHCP DNS at `<beacon's address>`. Blocky answers `<domain>` and every app's
   subdomain with beacon's address, so the LAN skips Cloudflare (no 100 MB upload cap, video
   doesn't go through it) and gets Forgejo's ssh: `git clone git@git.<domain>:<user>/<repo>.git`.

## Auto rebuild

Every 5 minutes `auto-rebuild` checks the `beacon` branch on Codeberg and, when it moved,
switches to exactly that commit (`git+<repo>?ref=beacon&rev=…`),
not to the checkout in `/etc/nixos`, with the vars from `/var/secrets/dotfiles/vars.toml`
(`vars/README.md`); without that file it does nothing but fail. Deploy by pushing there:

```sh
git push origin master:beacon
```

A commit that fails to build or switch is tried once and pushed to ntfy's `alerts`; the next
push is tried again. A manual `rebuild` still works and stays until the branch moves again.
`journalctl -u auto-rebuild` shows what it did, `/var/lib/auto-rebuild/rev` what it's on.
Anyone who can push to the branch is root on beacon.

## Logins

Everything is behind Tinyauth (`https://auth.<domain>`) but what's used from phone apps,
browser extensions or other clients that can't follow a browser login. The first visit goes to
Pocket ID, your passkey logs you in, and the session cookie covers every subdomain.

- **Behind Tinyauth:** `home`, `status`, `notes`, `pdf`, `sync`, `files`, `search`, `flow`,
  `watch`, `recipes`, `draw`, `metrics`, `disks`.
- **Their own login:** Vaultwarden, Forgejo, Miniflux, Paperless, Immich, Jellyfin,
  Audiobookshelf, ntfy, Linkding, Actual (its desktop app syncs), Vikunja, Radicale, Navidrome
  and Atuin. wastebin is public.

Forgejo, Miniflux, Paperless, Vikunja and Mealie can offer Pocket ID next to their own login
once their client is sealed; Immich and Audiobookshelf have it in their admin settings.

1. Make the Pocket ID admin at `https://id.<domain>/setup`: username `<username>`, the same
   email as in git, and register a passkey.
2. Seal the Pocket ID clients: `modules/nixos/services/k3s/manifests/oidc/README.md`.

Passwords are generated in the cluster on first start, never in git. Read one with
`sudo k3s kubectl -n <app> get secret <app> -o jsonpath='{.data.<KEY>}' | base64 -d`.

| App         | Login                                                             |
|-------------|-------------------------------------------------------------------|
| Forgejo     | `<username>`, `ADMIN_PASSWORD`; git over ssh on the LAN           |
| Miniflux    | `<username>`, `ADMIN_PASSWORD`                                    |
| Paperless   | `<username>`, `ADMIN_PASSWORD`                                    |
| ntfy        | `admin`, `ADMIN_PASSWORD`; subscribe to `alerts`                  |
| Vaultwarden | `/admin` with `ADMIN_TOKEN`, invite yourself, then register       |
| Linkding    | `<username>`, `ADMIN_PASSWORD`; the extension takes an API token  |
| FileBrowser | `<username>` through Tinyauth; tank as you, photos excluded       |
| Radicale    | `<username>`, `ADMIN_PASSWORD`; CalDAV/CardDAV at `cal`           |
| Navidrome   | `admin`, `ADMIN_PASSWORD`; rename it in the app                   |
| Vikunja     | `<username>`, `ADMIN_PASSWORD`, made once, see `k3s/manifests/vikunja.yaml` |

Only possible in the apps themselves: the first Immich user (becomes admin), Jellyfin's setup
wizard and libraries (`/media/music`, `/media/video`).

And for the newer ones:

- **Audiobookshelf** (`books`, not behind Tinyauth for the phone apps): the first visit makes
  the root user. Libraries: `/books` (`/srv/tank/books`, yours) and `/podcasts`.
- **Actual** (`budget`): set its server password on the first visit; it guards the budget
  files, which sync through the server.
- **Syncthing** (`sync`): leave the GUI user and password unset, Tinyauth covers it. Add folders
  under `/sync` (`/srv/tank/sync`); devices connect at `tcp://<beacon's address>:22000`.
- **SilverBullet** (`notes`): every page is a `.md` file in `/srv/tank/notes`, yours to edit.
- **wastebin** (`bin`): public, like Vaultwarden: anyone can make and read pastes.
- **SearXNG** (`search`): add `https://search.<domain>/search?q=%s` as the browser's search
  engine.

- **Atuin** (`sh`): registration is closed; open it for your first `atuin register`, the
  commands are in `k3s/manifests/atuin.yaml`. Set `sync_address = "https://sh.<domain>"`.
- **n8n** (`flow`): makes its owner account on the first visit, behind Tinyauth. Webhooks and
  forms (`/webhook/`, `/form/`) skip Tinyauth so other services can call them.
- **Mealie** (`recipes`): first login `changeme@example.com` / `MyPassword`; change both, the
  email to yours, so Pocket ID matches it.
- **changedetection.io** (`watch`): notify ntfy with `ntfys://ntfy.<domain>/<topic>`.
- **Beszel** (`metrics`) and **Scrutiny** (`disks`) run on the host, not k3s. Beszel logs you in
  by your Pocket ID email: make its user with that email on the first visit, then Add System,
  host `127.0.0.1`, port `45876`. Their data is regenerable and isn't backed up.

SilverBullet, Syncthing and FileBrowser run as `<username>` (uid 1000), so what they write on tank
is yours.
