# beacon

Home server. Apps run on k3s behind nginx and Cloudflare. Config: `default.nix`.

## Cheat sheet

| I want to…                 | Run                                                                        |
|----------------------------|----------------------------------------------------------------------------|
| Deploy a change            | `git push origin master:beacon`                                            |
| See what the deploy did    | `journalctl -u auto-rebuild`                                               |
| See which commit is live   | `cat /var/lib/auto-rebuild/rev`                                            |
| Read an app's password     | `sudo k3s kubectl -n <app> get secret <app> -o jsonpath='{.data.<KEY>}' \| base64 -d` |
| Get failure alerts         | Subscribe to `alerts` in ntfy                                              |

## Disks

| Disk               | Label     | Mount          | Holds                                          |
|--------------------|-----------|----------------|------------------------------------------------|
| Kingston 480G SSD  | (system)  | `/`            | OS, k3s, app data and databases (`/srv/apps`)  |
| WD Green 120G SSD  | `cache`   | `/srv/cache`   | Thumbnails, metadata, ML models (regenerable)  |
| Barracuda 2T HDD   | `scratch` | `/srv/scratch` | Transcodes (throwaway)                         |
| ST6000NM0034 6T    | `tank`    | `/srv/tank`    | Your files: music, video, photos, docs, notes, books, sync |
| ST6000NM0034 6T    | `backup`  | `/srv/backup`  | Backups of tank and k3s                        |

- Disks are found by label, so `sdX` names changing doesn't matter.
- Every disk but the system SSD can be missing: beacon still boots, and the apps that need it
  fail instead of filling the system SSD.
- tank and backup are btrfs and get scrubbed monthly. If a file rots on one, the good copy is on
  the other.

## Backups

| Job            | When   | What                                      | Where                         | Kept                        |
|----------------|--------|-------------------------------------------|-------------------------------|-----------------------------|
| **btrbk-tank** | Daily  | Snapshots of everything on tank           | `/srv/tank/.btrbk`            | 14 days                     |
|                |        | …sent to the backup disk                  | `/srv/backup/tank`            | 14 daily, 8 weekly, 6 monthly |
| **k3s-backup** | 03:30  | App data, databases, the cluster and its Secrets (incl. the sealed-secrets key) | `/srv/backup/k3s-state/<date>` | 14 days |

- A failed backup sends an alert to ntfy.
- Deleted video still takes space on the backup disk for 6 months.
- Everything is on one machine: this protects against mistakes and a dead disk, **not fire or theft**.

## First-time setup

**1. Build.** Run `rebuild` on beacon. Safe before the disks are formatted.

**2. Format the disks.**  **This erases them.**

Find the disks. The two 6T ones look the same, so tell them apart by serial:

```sh
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,LABEL
```

Then, using the `/dev/disk/by-id/` paths for the 6T disks:

```sh
sudo wipefs -a /dev/disk/by-id/<tank-disk> /dev/disk/by-id/<backup-disk> /dev/sdb /dev/sda
sudo mkfs.btrfs -L tank   -d single -m dup /dev/disk/by-id/<tank-disk>
sudo mkfs.btrfs -L backup -d single -m dup /dev/disk/by-id/<backup-disk>
sudo mkfs.ext4  -L cache   /dev/sdb
sudo mkfs.ext4  -L scratch /dev/sda
sudo systemctl start srv-tank.mount srv-backup.mount srv-cache.mount srv-scratch.mount
sudo systemctl restart k3s-app-dirs
```

The apps start by themselves a moment later.

<details>
<summary>Already have the old two-disk raid1 <code>tank</code> with data on it?</summary>

Split it without losing anything:

```sh
sudo btrfs balance start -dconvert=single -mconvert=dup /srv/tank
sudo btrfs device remove /dev/disk/by-id/<backup-disk> /srv/tank
sudo mkfs.btrfs -f -L backup -d single -m dup /dev/disk/by-id/<backup-disk>
```

</details>

**3. Point the router's DNS at beacon.** Set the router's DHCP DNS to `<beacon's address>`. At
home, apps then skip Cloudflare (faster, no 100 MB upload limit) and git over ssh works:
`git clone git@git.<domain>:<user>/<repo>.git`.

**4. Set up logins.** See [Logins](#logins).

## Deploying

```sh
git push origin master:beacon
```

That's it. Every 5 minutes beacon checks the `beacon` branch on Codeberg and switches to the new
commit.

- It needs `/var/secrets/dotfiles/vars.toml` (see `vars/README.md`), otherwise it just fails.
- It builds the pushed commit, not the checkout in `/etc/nixos`.
- A broken commit is tried once and sends an alert. Push a fix to try again.
- A manual `rebuild` works too, until the next push replaces it.
-  Anyone who can push to `beacon` is root on beacon.

## Logins

### Once

1. Go to `https://id.<domain>/setup` and create the admin: username `<username>`, your git email,
   and a passkey.
2. Optional: let apps log in with Pocket ID, see
   [`oidc/README.md`](../../modules/nixos/services/k3s/manifests/oidc/README.md).

### How it works

- ** Tinyauth apps:** you log in once with your passkey, and it covers all of them.
- ** Own login:** apps that phone apps, extensions or other clients talk to. They have their
  own password.
- Passwords are generated on the server, never stored in git. Read one with the command in the
  [cheat sheet](#cheat-sheet).

### Apps

All at `https://<subdomain>.<domain>`.

| App               | Subdomain | Login | First time                                                          |
|-------------------|-----------|-------|---------------------------------------------------------------------|
| Glance            | `home`    |     |                                                                     |
| Gatus             | `status`  |     |                                                                     |
| SilverBullet      | `notes`   |     | Pages are `.md` files in `/srv/tank/notes`                          |
| Stirling PDF      | `pdf`     |     |                                                                     |
| FileBrowser       | `files`   |     | Shows tank, except photos                                           |
| SearXNG           | `search`  |     | Browser search engine: `https://search.<domain>/search?q=%s`        |
| n8n               | `flow`    |     | Create the owner account. `/webhook/` and `/form/` are public       |
| changedetection   | `watch`   |     | Notify with `ntfys://ntfy.<domain>/<topic>`                         |
| Mealie            | `recipes` |     | Log in as `changeme@example.com` / `MyPassword`, change both (email to your Pocket ID one) |
| Excalidraw        | `draw`    |     |                                                                     |
| Beszel            | `metrics` |     | Create a user with your Pocket ID email, then Add System: `127.0.0.1`, port `45876` |
| Scrutiny          | `disks`   |     |                                                                     |
| Vaultwarden       | `vault`   |     | Open `/admin` with `ADMIN_TOKEN`, invite yourself, register         |
| Forgejo           | `git`     |     | `<username>` / `ADMIN_PASSWORD`                                     |
| Miniflux          | `rss`     |     | `<username>` / `ADMIN_PASSWORD`                                     |
| Paperless         | `docs`    |     | `<username>` / `ADMIN_PASSWORD`                                     |
| ntfy              | `ntfy`    |     | `admin` / `ADMIN_PASSWORD`, subscribe to `alerts`                   |
| Linkding          | `links`   |     | `<username>` / `ADMIN_PASSWORD`. The extension uses an API token    |
| Radicale          | `cal`     |     | `<username>` / `ADMIN_PASSWORD`, for CalDAV/CardDAV                 |
| MeTube            | `dl`      |     | Paste a link, pick Audio for Navidrome (`/music`), Video for Jellyfin (`/video`) |
| qBittorrent       | `torrent` |     | Add a `.torrent` or a magnet link; pick a category: `movies` and `series` go to `/video/` for Jellyfin, `general` to `/torrents`. Forward 6881 tcp/udp on the router to seed |
| Navidrome         | `music`   |     | `admin` / `ADMIN_PASSWORD`, rename it in the app                    |
| Vikunja           | `tasks`   |     | `<username>` / `ADMIN_PASSWORD` (see `k3s/manifests/vikunja.yaml`)  |
| Immich            | `photos`  |     | The first user you create is admin                                  |
| Jellyfin          | `media`   |     | Run the wizard. Libraries: `/media/music`, `/media/video`           |
| Audiobookshelf    | `books`   |     | First visit creates root. Libraries: `/books`, `/podcasts`          |
| Actual            | `budget`  |     | Set the server password on first visit                              |
| Atuin             | `sh`      |     | Open registration once to `atuin register` (see `k3s/manifests/atuin.yaml`). Set `sync_address = "https://sh.<domain>"` |
| wastebin          | `bin`     |     | Public: anyone can paste                                            |

Notes:

- Immich and Audiobookshelf can add Pocket ID in their own admin settings.
- SilverBullet and FileBrowser run as you (uid 1000), so their files on tank are yours.
- Beszel and Scrutiny run on the host, not k3s, and aren't backed up (their data is regenerable).
- ArchiSteamFarm (`asf`) has no URL. Give it a bot login once: `k3s kubectl -n asf create secret generic asf-bot --from-file=farm.json=<file>`, where `farm.json` has `SteamLogin`, `SteamPassword` and `GamesPlayedWhileIdle`. Control it with `k3s kubectl -n asf port-forward deploy/asf 1242:1242`. For Steam Guard, run `bash modules/nixos/services/k3s/asf-login.sh` from the checkout, then type the code or `Y`.
