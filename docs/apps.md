# Apps

All apps live at `https://<subdomain>.<domain>`. Defined in `modules/nixos/services/k3s/apps.nix`,
with manifests in `modules/nixos/services/k3s/manifests/`. Enable one by adding its name to
`k3s.apps` in `hosts/beacon/default.nix`.

## Login types

- **Tinyauth:** the passkey gate in front of the app (`auth = true` in `apps.nix`).
- **Pocket ID:** the app's "log in with Pocket ID" button, once its client is sealed. See [pocket-id.md](pocket-id.md).
- **Own:** the app's own username and password.
- **None:** no login.

## Apps

| App               | Subdomain | Login                       | First time                                                                                  |
|-------------------|-----------|-----------------------------|---------------------------------------------------------------------------------------------|
| Glance            | `home`    | Tinyauth                    |                                                                                             |
| Gatus             | `status`  | Tinyauth                    |                                                                                             |
| SilverBullet      | `notes`   | Tinyauth                    | Pages are `.md` files in `/srv/tank/notes`                                                  |
| Stirling PDF      | `pdf`     | Tinyauth                    |                                                                                             |
| FileBrowser       | `files`   | Tinyauth                    | Shows tank, except photos                                                                   |
| SearXNG           | `search`  | Tinyauth                    | Browser search engine: `https://search.<domain>/search?q=%s`                                |
| n8n               | `flow`    | Own                         | Create the owner account. `/webhook/` and `/form/` are public                               |
| changedetection   | `watch`   | Tinyauth                    | Notify with `ntfys://ntfy.<domain>/<topic>`                                                 |
| Mealie            | `recipes` | Tinyauth, Pocket ID         | Log in as `changeme@example.com` / `MyPassword`, change both (email to your Pocket ID one)  |
| Excalidraw        | `draw`    | Tinyauth                    |                                                                                             |
| Beszel            | `metrics` | Own (on the host)           | Create a user with your Pocket ID email, then Add System: `127.0.0.1`, port `45876`         |
| Scrutiny          | `disks`   | Own (on the host)           |                                                                                             |
| Vaultwarden       | `vault`   | Own, Pocket ID              | Open `/admin` with `ADMIN_TOKEN`, invite yourself, register                                 |
| Forgejo           | `git`     | Own, Pocket ID              | `<username>` / `ADMIN_PASSWORD`                                                             |
| Miniflux          | `rss`     | Own, Pocket ID              | `<username>` / `ADMIN_PASSWORD`                                                             |
| Paperless         | `docs`    | Own, Pocket ID              | `<username>` / `ADMIN_PASSWORD`                                                             |
| ntfy              | `ntfy`    | Own                         | `admin` / `ADMIN_PASSWORD`, subscribe to `alerts`                                           |
| Linkding          | `links`   | Own, Pocket ID              | `<username>` / `ADMIN_PASSWORD`. The extension uses an API token                            |
| Radicale          | `cal`     | Own                         | `<username>` / `ADMIN_PASSWORD`, for CalDAV/CardDAV                                         |
| MeTube            | `dl`      | Tinyauth                    | Paste a link, pick Audio for Navidrome (`/music`), Video for Jellyfin (`/video`)            |
| qBittorrent       | `torrent` | Tinyauth                    | Add a `.torrent` or a magnet link; pick a category: `movies` and `series` go to `/video/` for Jellyfin, `general` to `/torrents`. Forward 6881 tcp/udp on the router to seed |
| Navidrome         | `music`   | Tinyauth                    | `admin` / `ADMIN_PASSWORD`, rename it in the app                                            |
| Vikunja           | `tasks`   | Own, Pocket ID              | `<username>` / `ADMIN_PASSWORD` (see `manifests/vikunja.yaml`)                              |
| Immich            | `photos`  | Own, Pocket ID              | The first user you create is admin                                                          |
| Jellyfin          | `media`   | Own                         | Run the wizard. Libraries: `/media/music`, `/media/video`                                   |
| Audiobookshelf    | `books`   | Own                         | First visit creates root. Libraries: `/books`, `/podcasts`                                  |
| Actual            | `budget`  | Pocket ID                   | Set the server password on first visit                                                      |
| Atuin             | `sh`      | Own                         | Open registration once to `atuin register` (see `manifests/atuin.yaml`). Set `sync_address = "https://sh.<domain>"` |
| wastebin          | `bin`     | None                        | Public: anyone can paste                                                                    |
| Pelican Panel     | `mc`      | Pocket ID (once sealed)     | See [minecraft.md](minecraft.md)                                                            |

## Notes

- Immich and Audiobookshelf can add Pocket ID in their own admin settings.
- SilverBullet and FileBrowser run as you (uid 1000), so their files on tank are yours.
- ArchiSteamFarm (`asf`) has no URL. Give it a bot login once:

  ```sh
  k3s kubectl -n asf create secret generic asf-bot --from-file=farm.json=<file>
  ```

  `farm.json` has `SteamLogin`, `SteamPassword` and `GamesPlayedWhileIdle`. Control it with
  `k3s kubectl -n asf port-forward deploy/asf 1242:1242`. For Steam Guard, run
  `bash modules/nixos/services/k3s/asf-login.sh` from the checkout, then type the code or `Y`.
