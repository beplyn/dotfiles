# Drive (ownCloud Infinite Scale)

Self-hosted file sync and sharing at `https://drive.<domain>`. Runs in k3s as `owncloud/ocis`.
Logins go through Pocket ID (`https://id.<domain>`). Config: `modules/nixos/services/k3s/manifests/ocis.yaml`
and the `ocis` entry in `apps.nix`.

## 1. Pocket ID clients

Create these in Pocket ID (`https://id.<domain>`, admin → OIDC clients).

| Client  | Type   | Redirect URIs                                                                 | Used by           |
|---------|--------|-------------------------------------------------------------------------------|-------------------|
| `ocis`  | Public | `https://drive.<domain>/`, `https://drive.<domain>/oidc-callback.html`, `https://drive.<domain>/oidc-silent-redirect.html` | Web (browser)     |
| Desktop | Native | `http://127.0.0.1`, `http://localhost`                                        | Desktop sync client |
| Mobile  | Native | `oc://android.owncloud.com` (Android), `oc://ios.owncloud.com` (iOS)         | Mobile apps       |

- The web client is the one oCIS is configured with. It needs no secret.
- Desktop and mobile apps need their own Pocket ID clients. They are not wired up by this repo yet;
  see [Limits](#limits).

## 2. Seal the web client

On beacon, from the repo:

```sh
sudo seal-oidc ocis > modules/nixos/services/k3s/manifests/oidc/ocis.sealed.yaml
```

Paste the client ID. For a public client, press Enter at the secret prompt. Then:

```sh
git add modules/nixos/services/k3s/manifests/oidc/ocis.sealed.yaml
git commit -m "ocis: seal oidc client"
git push origin master:beacon   # deploys; see docs/beacon.md
```

Until the sealed file exists, the pod still starts, but the web client ID is the default `web`
and Pocket ID logins fail.

## 3. DNS and proxy

Nothing to add by hand. `drive` is a proxied host, so:

- nginx serves `drive.<domain>` over TLS and forwards to the NodePort (`30104`).
- Blocky maps `drive.<domain>` to beacon's LAN address, so LAN clients skip Cloudflare.
  Outside the LAN, the DDNS record points the name at beacon.
- The upload limit at Cloudflare is 100 MB, so big uploads must happen on the LAN.

## 4. First login

Each Pocket ID user gets an oCIS account on their first sign-in (`PROXY_AUTOPROVISION_ACCOUNTS`).
Check the first login in the logs:

```sh
k3s kubectl -n ocis logs deploy/ocis --tail=50
```

Data lives on beacon's system disk at `/srv/apps/ocis` (`OCIS_BASE_DATA_PATH` in the pod is
`/var/lib/ocis`), so it's included in the k3s backup.

## Secrets

oCIS needs four generated keys, stored in the `ocis` Secret by `secrets.sh`:
`OCIS_JWT_SECRET`, `OCIS_TRANSFER_SECRET`, `OCIS_MACHINE_AUTH_API_KEY`, `OCIS_SERVICE_ACCOUNT_SECRET`.
Read one with `sudo k3s kubectl -n ocis get secret ocis -o jsonpath='{.data.<KEY>}' | base64 -d`.

## Limits

- Desktop and mobile sign-in: unverified. oCIS needs to accept tokens from those clients, which is a
  proxy setting not yet added here.
- `GRAPH_LDAP_SERVER_WRITE_ENABLED` is set for autoprovisioning, per the oCIS docs. Check the first
  login; if provisioning fails, this is the first thing to look at.
- The image is pinned to `owncloud/ocis:8.2`. Upgrade by changing the tag and reading the release notes first.
