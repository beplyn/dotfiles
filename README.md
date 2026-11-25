# dotfiles

NixOS config for beacon (home server), anvil and shulker (desktops). Every host and theme is one
flake output, `<host>-<theme>`.

Start with [docs/install.md](docs/install.md) for a fresh machine, or [docs/layout.md](docs/layout.md) to find your way around.

## Docs

| Guide                                        | About                                                    |
|----------------------------------------------|----------------------------------------------------------|
| [layout.md](docs/layout.md)                  | Repo layout, adaptive options, adding hosts and apps     |
| [install.md](docs/install.md)                | Fresh install with `install.sh`                          |
| [rebuild.md](docs/rebuild.md)                | `rebuild` by hand, and auto-rebuild on beacon            |
| [vars.md](docs/vars.md)                      | Your values (domain, email, LAN), kept out of the repo   |
| [secrets.md](docs/secrets.md)                | Where each kind of secret lives and how it's set         |
| [beacon.md](docs/beacon.md)                  | beacon overview and cheat sheet                          |
| [disks.md](docs/disks.md)                    | Disk layout and first-time formatting                    |
| [backups.md](docs/backups.md)                | btrbk snapshots and the k3s state backup                 |
| [apps.md](docs/apps.md)                      | Every k3s app, its login, and first-time setup           |
| [logins.md](docs/logins.md)                  | Tinyauth passkey and first-time admin setup              |
| [pocket-id.md](docs/pocket-id.md)            | Pocket ID OIDC clients, sealed with `seal-oidc`          |
| [networking.md](docs/networking.md)          | Public names, LAN DNS (Blocky), WireGuard, ports         |
| [minecraft.md](docs/minecraft.md)            | Pelican Panel, Wings, mc-router, wake-on-join, idle stop |

Licence: see [LICENSE](LICENSE).
