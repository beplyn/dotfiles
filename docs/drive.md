# Drive (ownCloud Infinite Scale)

Self-hosted file sync and sharing at `https://drive.<domain>`. Runs in k3s as `owncloud/ocis:8.2`.
Logins go through Pocket ID (`https://id.<domain>`). Config: `modules/nixos/services/k3s/manifests/ocis.yaml`
and the `ocis` entry in `apps.nix`.

## 1. Pocket ID clients

Create these in Pocket ID (`https://id.<domain>`, admin → OIDC clients).

| Client                | Type   | Redirect URIs                                                                                  | Used by             |
|-----------------------|--------|------------------------------------------------------------------------------------------------|---------------------|
| Web (`ocis`)          | Public | `https://drive.<domain>/`, `https://drive.<domain>/oidc-callback.html`, `https://drive.<domain>/oidc-silent-redirect.html` | Browser |
| Desktop               | Native | `http://127.0.0.1:*`, `http://localhost:*`                                                     | Desktop sync client |
| Android               | Native | `oc://android.owncloud.com`                                                                     | Android app        |
| iOS                   | Native | `oc://ios.owncloud.com`                                                                         | iOS app            |

The desktop and mobile apps use built-in client IDs, which the official Keycloak example registers:

| App     | Client ID                                                             |
|---------|-----------------------------------------------------------------------|
| Desktop | `xdXOt13JKxym1B1QcEncf2XDkLAexMBFwiT9j6EfhhHFJhs2KM9jbjTmf8JBXE69`    |
| Android | `e4rAsNUSIUs0lF4nbv9FmCeUkTlV9GdgTLDH1b5uie7syb90SzEVrbN7HIpmWJeD`    |
| iOS     | `mxd5OQDk6es5LzOzRvidJNfXLUZS2oN3oUFeXPP8LpPrhx3UroJFduGEYIBOxkY1`    |

- **Unconfirmed:** whether Pocket ID accepts these IDs as custom client IDs. If it doesn't, the apps
  can't sign in with Pocket ID, and this needs a different approach.
- The Keycloak example registers the Android and iOS clients as confidential, and the desktop client
  likely as confidential too. Check the client type in Pocket ID against what each app expects.
- The web client needs no secret. See step 2.

## 2. Seal the web client

On beacon, from the repo:

```sh
sudo seal-oidc ocis > modules/nixos/services/k3s/manifests/oidc/ocis.sealed.yaml
```

Paste the client ID. For a public client, press Enter at the secret prompt. Then commit the sealed
file and deploy with `git push origin master:beacon` (see [beacon.md](beacon.md)).

Until the sealed file exists, the pod still starts, but the web client ID falls back to `web` and
Pocket ID logins fail.

## 3. Token checks

Leave `PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD` at its default, `jwt`. oCIS then verifies token
signatures against the Pocket ID JWKS. The Keycloak example doesn't change it. Setting `none` would
skip signature checks, which is the wrong trade-off for an internet-facing service.

`PROXY_OIDC_ACCESS_TOKEN_VERIFY_AUD` is empty by default, so every client's tokens are accepted. Set it
only to restrict which clients can sign in.

## 4. DNS and proxy

Nothing to add by hand. `drive` is a proxied host, so:

- nginx serves `drive.<domain>` over TLS and forwards to the NodePort (`30104`).
- AdGuard maps `drive.<domain>` to beacon's LAN address, so LAN clients skip Cloudflare.
  Outside the LAN, the DDNS record points the name at beacon.
- Cloudflare limits uploads to 100 MB, so big uploads work best on the LAN.

## 5. First login

Each Pocket ID user gets an oCIS account on their first sign-in (`PROXY_AUTOPROVISION_ACCOUNTS`).
Check the first login in the logs:

```sh
k3s kubectl -n ocis logs deploy/ocis --tail=50
```

Data is on beacon's system disk at `/srv/apps/ocis` (the pod's `OCIS_BASE_DATA_PATH` is
`/var/lib/ocis`), so it's included in the k3s backup.

## Secrets

oCIS needs four generated keys, stored in the `ocis` Secret by `secrets.sh`:
`OCIS_JWT_SECRET`, `OCIS_TRANSFER_SECRET`, `OCIS_MACHINE_AUTH_API_KEY`, `OCIS_SERVICE_ACCOUNT_SECRET`.
Read one with `sudo k3s kubectl -n ocis get secret ocis -o jsonpath='{.data.<KEY>}' | base64 -d`.

The names come from the oCIS 8.2 env-var reference. Their exact purpose is only partly confirmed,
and the Keycloak example doesn't set them; it relies on `ocis init` to generate the config.

## Limits

- Desktop and mobile sign-in with Pocket ID: unconfirmed (see the client IDs above).
- `GRAPH_LDAP_SERVER_WRITE_ENABLED` is set for autoprovisioning, per the oCIS docs. If provisioning fails
  on a first login, check this first.
- Upgrades: change the image tag, then read the oCIS release notes first.
