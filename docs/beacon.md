# beacon

Home server. Apps run on k3s behind nginx and Cloudflare. Config: `hosts/beacon/`.

## Cheat sheet

| I want to…                 | Run                                                                                              |
|----------------------------|--------------------------------------------------------------------------------------------------|
| Deploy a change            | `git push origin master:beacon`                                                                  |
| See what the deploy did    | `journalctl -u auto-rebuild`                                                                     |
| See which commit is live   | `cat /var/lib/auto-rebuild/rev`                                                                  |
| Read an app's password     | `sudo k3s kubectl -n <app> get secret <app> -o jsonpath='{.data.<KEY>}' \| base64 -d`            |
| Get failure alerts         | Subscribe to `alerts` in ntfy                                                                    |

## Guides

| Topic                       | File                                  |
|-----------------------------|---------------------------------------|
| Deploying and rebuilding    | [rebuild.md](rebuild.md)              |
| Disks and formatting        | [disks.md](disks.md)                  |
| Backups                     | [backups.md](backups.md)              |
| Apps and their first login  | [apps.md](apps.md)                    |
| Tinyauth and Pocket ID      | [logins.md](logins.md), [pocket-id.md](pocket-id.md) |
| LAN, DNS and WireGuard      | [networking.md](networking.md)        |
| Minecraft                   | [minecraft.md](minecraft.md)          |
| Secrets                     | [secrets.md](secrets.md)              |
| Vars (your values)          | [vars.md](vars.md)                    |
