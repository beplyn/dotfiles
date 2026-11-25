# Backups

Config: `hosts/beacon/storage.nix` (btrbk) and `modules/nixos/services/k3s/backup/` (app state).

| Job            | When   | What                                                                            | Where                          | Kept                          |
|----------------|--------|---------------------------------------------------------------------------------|--------------------------------|-------------------------------|
| **btrbk-tank** | Daily  | Snapshots of everything on tank                                                 | `/srv/tank/.btrbk`             | 14 days                       |
|                |        | …sent to the backup disk                                                        | `/srv/backup/tank`             | 14 daily, 8 weekly, 6 monthly |
| **k3s-backup** | 03:30  | App data, databases, the cluster and its Secrets (incl. the sealed-secrets key) | `/srv/backup/k3s-state/<date>` | 14 days                       |

- A failed backup sends an alert to ntfy.
- Deleted video still takes space on the backup disk for 6 months.
- Everything is on one machine. This protects against mistakes and a dead disk, **not fire or theft**.
- Beszel and Scrutiny run on the host, not k3s, and aren't backed up: their data is regenerable.
