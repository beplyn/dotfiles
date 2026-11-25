# Rebuilding

Two ways to apply the config. Both build `<host>-<theme>` from the flake.

| Way         | Runs on         | Source                                | Trigger                       |
|-------------|-----------------|---------------------------------------|-------------------------------|
| `rebuild`   | Any host        | `/etc/nixos`, your local checkout     | You run it                    |
| auto-rebuild | Hosts with `rebuild.auto.enable` (beacon) | The pushed commit on the host's branch | Every 5 minutes |

## Manual: `rebuild`

```sh
rebuild            # current theme
rebuild nord       # another theme
```

Run as your user. It:

1. Creates your GPG and SSH keys if missing.
2. Asks for any value missing from `vars.toml` and any host secret in `rebuild.secrets`.
3. Stages new files (`git add --intent-to-add`); it never commits.
4. Runs `sudo nixos-rebuild switch --flake /etc/nixos#<host>-<theme> --override-input vars path:/var/secrets/dotfiles`.
5. Restarts units that were waiting on a new secret.

Use another checkout with `DOTFILES=/path/to/repo rebuild`. The default is wherever `/etc/nixos`
points.

## Automatic: beacon

Config: `modules/nixos/base/rebuild/default.nix`. Enable with `rebuild.auto.enable = true`.

```sh
git push origin master:beacon
```

Every 5 minutes beacon:

1. Asks the repo (`rebuild.auto.url`) for the newest commit on `rebuild.auto.branch` (default: the host name).
2. Does nothing if that commit is already live, or already failed.
3. Otherwise builds that exact commit with `nixos-rebuild switch`. It never builds `/etc/nixos`, so
   local edits and untracked files on the host have no effect.
4. Records the commit in `/var/lib/auto-rebuild/rev` on success, or `failed` on failure.

A failed build leaves the running system as it was. The unit fails once, which sends an ntfy
alert; later runs skip that commit and wait for the next push. If the remote can't be reached
(network down, timeout), the unit fails and alerts, and the next run tries again.

### Commands

| I want to…               | Run                                                                 |
|--------------------------|---------------------------------------------------------------------|
| See the last run         | `journalctl -u auto-rebuild`                                        |
| See the live commit      | `cat /var/lib/auto-rebuild/rev`                                     |
| See the failed commit    | `cat /var/lib/auto-rebuild/failed`                                  |
| Retry the failed commit  | `sudo rm /var/lib/auto-rebuild/failed && sudo systemctl start auto-rebuild` |

### Requirements

- `/var/secrets/dotfiles/vars.toml` exists with real values. Without it the run fails.
- Anyone who can push to the branch is root on that host.

## Scripts at a glance

| Script                                          | Purpose                                      |
|-------------------------------------------------|----------------------------------------------|
| `install.sh`                                    | First install, see [install.md](install.md)  |
| `modules/nixos/base/rebuild/rebuild.sh`         | `rebuild`: keys, secrets, switch            |
| `modules/nixos/base/rebuild/auto-rebuild.sh`    | Timer job on auto-rebuild hosts             |
| `modules/nixos/base/rebuild/vars.sh`            | Asks for missing vars, see [vars.md](vars.md) |
