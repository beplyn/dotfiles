# Pocket ID clients

One per app with `oidc = true` in `apps.nix`. Each is optional: until its sealed `<app>-oidc`
Secret is here, the app has only its own login, apart from Tinyauth, which lets nobody past
without it.

| App       | Callback URL                                                      |
|-----------|-------------------------------------------------------------------|
| tinyauth  | `https://auth.<domain>/api/oauth/callback/pocketid`             |
| forgejo   | `https://git.<domain>/user/oauth2/pocket-id/callback`           |
| miniflux  | `https://rss.<domain>/oauth2/oidc/callback`                     |
| paperless | `https://docs.<domain>/accounts/oidc/pocket-id/login/callback/` |
| vikunja   | `https://tasks.<domain>/auth/openid/pocketid`                   |
| mealie    | `https://recipes.<domain>/login`                                |

1. In Pocket ID (`https://id.<domain>`), add an OIDC client with the app's callback URL.
2. On beacon, from the repo:
   `sudo seal-oidc <app> > modules/nixos/services/k8s/oidc/<app>.sealed.yaml`
   and paste the client ID and secret it shows.
3. `git add` the file, commit, push, rebuild.

Only Vikunja makes accounts through Pocket ID; link it to `<username>` once:

- **Forgejo**: the first Pocket ID sign-in asks for the Forgejo password, then remembers it.
- **Miniflux**: Settings, "Link my Pocket ID account".
- **Paperless**: My Profile, connect Pocket ID.
- **Vikunja** and **Mealie**: matched by email, so give the account your Pocket ID email;
  without a match Vikunja makes a second one.

Not here: Immich and Audiobookshelf take Pocket ID in their own admin settings (callbacks
`https://photos.<domain>/auth/login`, `app.immich:///oauth-callback` and
`https://books.<domain>/auth/openid/callback`, `audiobookshelf://oauth`). Linkding would make
a second account, and Vaultwarden, Jellyfin, ntfy, Actual, Radicale, Navidrome and Atuin keep
only their own.
