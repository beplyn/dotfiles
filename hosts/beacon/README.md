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
| ST6000NM0034 6T HDD     | `tank`    | `/srv/tank`    | music, video, photos, documents (btrfs subvolumes) |
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

1. Push a signed commit; auto-deploy switches to it. The disks are `nofail`, so this is safe
   before they exist.
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

3. Point the router's DHCP DNS at `192.168.2.200`. Blocky answers `beplyn.dev` and every app's
   subdomain with beacon's address, so the LAN skips Cloudflare (no 100 MB upload cap, video
   doesn't go through it) and gets Forgejo's ssh: `git clone git@git.beplyn.dev:<user>/<repo>.git`.

## Logins

Generated in the cluster on first start, never in git. Read one with
`sudo k3s kubectl -n <app> get secret <app> -o jsonpath='{.data.<KEY>}' | base64 -d`.

| App         | Login                                                         |
|-------------|---------------------------------------------------------------|
| Forgejo     | `beplyn`, `ADMIN_PASSWORD`                                    |
| Miniflux    | `admin`, `ADMIN_PASSWORD`                                     |
| Paperless   | `admin`, `ADMIN_PASSWORD`                                     |
| ntfy        | `admin`, `ADMIN_PASSWORD`; subscribe to `alerts`              |
| Vaultwarden | `/admin` with `ADMIN_TOKEN`, invite yourself, then register   |

Only possible in the apps themselves: the Pocket ID admin's passkey (`https://id.beplyn.dev/setup`),
the first Immich user (becomes admin), Jellyfin's setup wizard and libraries
(`/media/music`, `/media/video`).

Pocket ID logins for the other apps: `modules/nixos/services/k8s/oidc/README.md`.
