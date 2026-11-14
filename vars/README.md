# vars

The values that say whose machines these are. `vars.toml` here only holds placeholders, so the
flake evaluates (and CI builds) without them. The real ones live outside the repo, root-only, in
`/var/secrets/dotfiles/vars.toml`; `rebuild`, `auto-rebuild` and `install.sh` evaluate with
`--override-input vars path:/var/secrets/dotfiles`, and `rebuild` and `install.sh` ask for any
value that file doesn't have yet.

| Value         | What it is                                                         |
|---------------|--------------------------------------------------------------------|
| `username`    | your login, also the git and service admin name                    |
| `email`       | git commits, ACME, Pocket ID and the app admins                    |
| `domain`      | the zone beacon serves its apps under                              |
| `repo`        | this repo's https URL; auto-rebuild polls it, git pushes over ssh  |
| `lan.address` | beacon's static address (other hosts: leave empty)                 |
| `lan.gateway` | the router: gateway and DNS for beacon                             |
| `lan.subnet`  | the LAN, let straight in past Cloudflare                           |

The template is marked `placeholder = true`, so a build without the real values fails instead
of making `user` at `example.com`; CI builds a copy without the marker.

Not private: whatever the config uses ends up in `/nix/store`, which every local user can read.
Real secrets (tokens, keys, passwords) go through `rebuild.secrets` and the sealed Secrets.
A new value added to `vars.toml` here is asked for on the next `rebuild`.
