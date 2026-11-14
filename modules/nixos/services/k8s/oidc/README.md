# Pocket ID client

Tinyauth is the only Pocket ID client: the apps behind it trust the Remote-User header nginx
passes on, so none of them registers with Pocket ID itself. Until its sealed `tinyauth-oidc`
Secret is here, nobody gets past Tinyauth.

1. In Pocket ID (`https://id.beplyn.dev`), add an OIDC client with the callback URL
   `https://auth.beplyn.dev/api/oauth/callback/pocketid`.
2. On beacon, from the repo:
   `sudo seal-oidc tinyauth > modules/nixos/services/k8s/oidc/tinyauth.sealed.yaml`
   and paste the client ID and secret it shows.
3. `git add` the file, commit, push, rebuild.

Not behind Tinyauth, logging in on their own: Vaultwarden, Jellyfin, Immich and ntfy, whose
apps and clients can't follow a browser login.
