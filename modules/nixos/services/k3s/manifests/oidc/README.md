# Pocket ID logins

Lets an app offer "log in with Pocket ID" next to its own login. Every app here is optional, except
**tinyauth**: nobody gets past Tinyauth until it's set up.

## Add one

1. In Pocket ID (`https://id.<domain>`), add an OIDC client with the app's callback URL (below).
2. On beacon, from the repo, run this and paste the client ID and secret:

   ```sh
   sudo k3s kubectl get svc -A -o wide
   ```

   ```sh
   sudo seal-oidc <app> > modules/nixos/services/k3s/manifests/oidc/<app>.sealed.yaml
   ```

3. `git add` the file, commit, push.

## Apps

| App       | Callback URL                                                    | Then                                             |
|-----------|-----------------------------------------------------------------|--------------------------------------------------|
| tinyauth  | `https://auth.<domain>/api/oauth/callback/pocketid`             | Nothing, do this one first                       |
| forgejo   | `https://git.<domain>/user/oauth2/pocket-id/callback`           | First sign-in asks for your Forgejo password once |
| miniflux  | `https://rss.<domain>/oauth2/oidc/callback`                     | Settings → "Link my Pocket ID account"           |
| paperless | `https://docs.<domain>/accounts/oidc/pocket-id/login/callback/` | My Profile → connect Pocket ID                   |
| vikunja   | `https://tasks.<domain>/auth/openid/pocketid`                   | Give your account your Pocket ID email first   |
| mealie    | `https://recipes.<domain>/login`                                | Give your account your Pocket ID email first     |

 Vikunja makes a **second** account if the emails don't match.

## Not here

- **Immich** and **Audiobookshelf**: set Pocket ID up in their own admin settings.

  | App            | Callback URLs                                                      |
  |----------------|--------------------------------------------------------------------|
  | Immich         | `https://photos.<domain>/auth/login`, `app.immich:///oauth-callback` |
  | Audiobookshelf | `https://books.<domain>/auth/openid/callback`, `audiobookshelf://oauth` |

- **No Pocket ID:** Linkding (it would make a second account), Vaultwarden, Jellyfin, ntfy, Actual,
  Radicale, Navidrome, Atuin.
