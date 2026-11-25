# Secrets

Nothing secret goes in git. Each kind of secret has one place:

| Secret                                  | Where it lives                                         | Set by                         |
|-----------------------------------------|--------------------------------------------------------|--------------------------------|
| Your values (domain, email, LAN, keys)  | `/var/secrets/dotfiles/vars.toml`                      | `install.sh`, `rebuild`        |
| Host secrets (WireGuard key, and more)  | Paths declared in `rebuild.secrets`, root-only         | `rebuild` asks                 |
| App passwords and tokens                | k3s `Secret` objects in each app's namespace           | `secrets.sh` (automatic)       |
| OIDC client ID and secret               | `manifests/oidc/<app>.sealed.yaml` (in git, encrypted) | `sudo seal-oidc <app>`         |
| Pelican Panel API token                 | `/var/lib/pelican/api-token`                           | You, by hand                   |
| Wings node config                       | `/etc/pelican/config.yml`                              | You, from the Panel            |

## Host secrets: `rebuild.secrets`

A module declares a root-only file, and `rebuild` asks for it when it's missing:

```nix
rebuild.secrets."/var/secrets/foo.token".description = "Foo API token";
```

- Delete the file to be asked again.
- `prefix` writes a value in front (for env files), `file = true` copies a local file (for a PEM).
- `restart` lists units to restart once the secret is written.
- Missing secrets don't stop the rebuild. Their services fail until you add them.

## App secrets: `secrets.sh`

Each app lists its generated keys in `apps.nix` (`secrets = [ ... ]`). When k3s starts, `secrets.sh` adds
any key that's missing to the app's Kubernetes `Secret` and never rotates existing ones.

| Spec in `apps.nix`             | Value                                       |
|--------------------------------|---------------------------------------------|
| `"KEY"`                        | Random 64-character hex                     |
| `"ALERT_TOKEN=ntfy-token"`     | An ntfy access token (`tk_…`)               |
| `"ADMIN_HASH=bcrypt:ADMIN_PASSWORD"` | A bcrypt hash of another key's value |

Read a value with the command in the [beacon cheat sheet](beacon.md#cheat-sheet).

## OIDC clients: `seal-oidc`

Client ID and secret from Pocket ID are sealed with the cluster key, so the encrypted file is safe to
commit. See [pocket-id.md](pocket-id.md).

```sh
sudo seal-oidc <app> > modules/nixos/services/k3s/manifests/oidc/<app>.sealed.yaml
```

The sealed-secrets key is in the k3s backup. Losing it means re-sealing every OIDC client.

## Pelican Panel API token

`pelican-mc-sync` reads the Panel API token from `/var/lib/pelican/api-token`. The sync doesn't start
until the file exists.

1. In the Panel, create an admin client API key.
2. Write it to the file, readable by root only:

   ```sh
   sudo install -m 0600 -o root -g root /dev/stdin /var/lib/pelican/api-token
   ```

   Paste the key, then press Ctrl-D.

3. Start the sync: `sudo systemctl restart pelican-mc-sync`.

See [minecraft.md](minecraft.md) for the rest of the stack.
