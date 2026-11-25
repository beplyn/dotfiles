# Disks

Config: `hosts/beacon/storage.nix`.

| Disk               | Label     | Mount          | Holds                                                      |
|--------------------|-----------|----------------|------------------------------------------------------------|
| Kingston 480G SSD  | (system)  | `/`            | OS, k3s, app data and databases (`/srv/apps`)              |
| WD Green 120G SSD  | `cache`   | `/srv/cache`   | Thumbnails, metadata, ML models (regenerable)              |
| Barracuda 2T HDD   | `scratch` | `/srv/scratch` | Transcodes (throwaway)                                     |
| ST6000NM0034 6T    | `tank`    | `/srv/tank`    | Your files: music, video, photos, docs, notes, books, sync |
| ST6000NM0034 6T    | `backup`  | `/srv/backup`  | Backups of tank and k3s                                    |

- Disks are mounted by label, so `sdX` names changing doesn't matter.
- Every disk but the system SSD can be missing: beacon still boots, and the apps that need it
  fail instead of filling the system SSD.
- `tank` and `backup` are btrfs and are scrubbed monthly. If a file rots on one, the good copy is
  on the other.

## First-time format

**This erases the disks.** Run `rebuild` on beacon first; it's safe before the disks are formatted.

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

The apps start on their own a moment later.

## Splitting an old two-disk raid1 `tank`

Only if `tank` is still a raid1 pair with data on it. This keeps the data:

```sh
sudo btrfs balance start -dconvert=single -mconvert=dup /srv/tank
sudo btrfs device remove /dev/disk/by-id/<backup-disk> /srv/tank
sudo mkfs.btrfs -f -L backup -d single -m dup /dev/disk/by-id/<backup-disk>
```
