# Pocket ID clients

One sealed `<app>-oidc` Secret per app, made with `seal-oidc` on beacon. An app picks its file
up on the next deploy; until then it runs with local logins only.

1. In Pocket ID (`https://id.beplyn.dev`), add an OIDC client with the callback URL below.
2. On beacon, from the repo:
   `sudo seal-oidc <app> > modules/nixos/services/k8s/oidc/<app>.sealed.yaml`
   and paste the client ID and secret it shows.
3. `git add` the file, commit, push.

| App         | Callback URL                                                    |
|-------------|-----------------------------------------------------------------|
| vaultwarden | `https://vault.beplyn.dev/identity/connect/oidc-signin`         |
| forgejo     | `https://git.beplyn.dev/user/oauth2/pocket-id/callback`         |
| miniflux    | `https://rss.beplyn.dev/oauth2/oidc/callback`                   |
| paperless   | `https://docs.beplyn.dev/accounts/oidc/pocket-id/login/callback/` |

Not here: Immich keeps its OAuth settings in its database (Administration, Authentication
Settings), and declaring them would lock every other setting in the UI. Jellyfin needs the
SSO plugin.
