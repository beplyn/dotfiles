# Pocket ID logins

Lets an app offer "log in with Pocket ID" next to its own login. Every app here is optional, except
**tinyauth**: nobody gets past Tinyauth until it's set up.

## Add one

1. In Pocket ID (`https://id.<domain>`), add an OIDC client with the app's callback URL (below).
2. On beacon, from the repo, run this and paste the client ID and secret:

   ```sh
   sudo seal-oidc <app> > modules/nixos/services/k3s/manifests/oidc/<app>.sealed.yaml
   ```

3. `git add` the file, commit, push.

## Apps

| App         | Callback URL                                                    | Then                                             |
|-------------|-----------------------------------------------------------------|--------------------------------------------------|
| tinyauth    | `https://auth.<domain>/api/oauth/callback/pocketid`             | Nothing, do this one first                       |
| forgejo     | `https://git.<domain>/user/oauth2/pocket-id/callback`           | Browser logins are Pocket ID only                |
| miniflux    | `https://rss.<domain>/oauth2/oidc/callback`                     | Settings → "Link my Pocket ID account"           |
| paperless   | `https://docs.<domain>/accounts/oidc/pocket-id/login/callback/` | My Profile → connect Pocket ID                   |
| vikunja     | `https://tasks.<domain>/auth/openid/pocketid`                   | Give your account your Pocket ID email first     |
| mealie      | `https://recipes.<domain>/login`                                | Give your account your Pocket ID email first     |
| vaultwarden | `https://vault.<domain>/identity/connect/oidc-signin`           | "Use single sign-on" on the login page           |
| immich      | `https://photos.<domain>/auth/login`, `app.immich:///oauth-callback` (phone) | Login button on the web and in the app |
| linkding    | `https://links.<domain>/oidc/callback/`                         | Login button; use the same email as your local account |
| actual      | `https://budget.<domain>/openid/callback`                       | Pocket ID is the only login (`ACTUAL_LOGIN_METHOD=openid`) |

Vikunja makes a **second** account if the emails don't match.

## Not here

- **Audiobookshelf**: set Pocket ID up in its own admin settings.
  Callback URLs: `https://books.<domain>/auth/openid/callback`, `audiobookshelf://oauth`.
- **No Pocket ID:** Jellyfin, ntfy, Radicale, Navidrome, Atuin. Navidrome and FileBrowser log in
  through Tinyauth's `Remote-User` header instead.
