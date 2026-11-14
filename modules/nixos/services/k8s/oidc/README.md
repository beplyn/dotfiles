# Pocket ID clients

One per app with `oidc = true` in `apps.nix`. Each is optional: until its sealed `<app>-oidc`
Secret is here, the app has only its own login, apart from Tinyauth, which lets nobody past
without it.

| App       | Callback URL                                                      |
|-----------|-------------------------------------------------------------------|
| tinyauth  | `https://auth.beplyn.dev/api/oauth/callback/pocketid`             |
| forgejo   | `https://git.beplyn.dev/user/oauth2/pocket-id/callback`           |
| miniflux  | `https://rss.beplyn.dev/oauth2/oidc/callback`                     |
| paperless | `https://docs.beplyn.dev/accounts/oidc/pocket-id/login/callback/` |

1. In Pocket ID (`https://id.beplyn.dev`), add an OIDC client with the app's callback URL.
2. On beacon, from the repo:
   `sudo seal-oidc <app> > modules/nixos/services/k8s/oidc/<app>.sealed.yaml`
   and paste the client ID and secret it shows.
3. `git add` the file, commit, push, rebuild.

None of them makes accounts through Pocket ID; link it to `beplyn` once:

- **Forgejo**: the first Pocket ID sign-in asks for the Forgejo password, then remembers it.
- **Miniflux**: Settings, "Link my Pocket ID account".
- **Paperless**: My Profile, connect Pocket ID.

Not here: Immich and Audiobookshelf take Pocket ID in their own admin settings (callbacks
`https://photos.beplyn.dev/auth/login`, `app.immich:///oauth-callback` and
`https://books.beplyn.dev/auth/openid/callback`, `audiobookshelf://oauth`). Linkding would make
a second account, and Vaultwarden, Jellyfin, ntfy, FileBrowser and Actual keep only their own.
