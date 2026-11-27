# Networking

## Public names

Cloudflare DNS points the apex and `*.<domain>` at beacon. The k3s DDNS job (`k3s.ddns`) keeps
that record current. Apps are proxied by nginx (`modules/nixos/services/proxy.nix`) with TLS.

- Web apps go through Cloudflare, which only passes HTTP(S).
- Records marked DNS-only skip Cloudflare: `mc` and `*.mc` for Minecraft, and git over SSH.

## LAN address and DNS

beacon has a static LAN address, set in `vars.toml` (`lan.*`, see [vars.md](vars.md)). Its
`networking.networkmanager` profile is in `hosts/beacon/network.nix`.

AdGuard Home (k3s, `manifests/adguard.yaml`) answers DNS on the LAN and blocks the lists it declares. Its `rewrites` map each proxied
name to beacon's LAN address, so at home:

- Apps are reached directly, faster, and without the 100 MB Cloudflare upload limit.
- Git over SSH works: `git clone git@git.<domain>:<user>/<repo>.git`.

To use it, set the router's DHCP DNS server to beacon's LAN address. Then a new app works at home
as soon as it's added to `apps.nix`.

## WireGuard (wg0)

beacon listens on UDP 51820 and is the only server. The desktops dial in, and SSH to beacon over
`10.100.0.1`. Config: `hosts/beacon/default.nix` (server) and `hosts/<desktop>/default.nix` (client).

- Each host's private key lives root-only in `/var/secrets/wireguard/wg0.key`; `rebuild` asks for it.
- Public keys go in `vars.toml` under `[wireguard]`, filled in with `scripts/wireguard/`.
- A peer with an empty public key is left out until its key is set.

Add a peer with `scripts/wireguard/peer.sh` (see its usage line) and rebuild beacon.

## Ports

| Port         | Proto    | For                                              | Opened by                              |
|--------------|----------|--------------------------------------------------|----------------------------------------|
| 80, 443      | TCP      | Web apps                                         | `modules/nixos/services/proxy.nix`     |
| 51820        | UDP      | WireGuard                                        | `modules/nixos/services/wireguard.nix` |
| 25565        | TCP, UDP | Minecraft (mc-router)                            | `modules/nixos/services/pelican`       |
| 22           | TCP      | Forgejo over SSH, LAN only                       | `lan.tcp` in `apps.nix`                |
| 6881         | TCP, UDP | qBittorrent peers (forward on the router)        | `lan.*` / router                       |

Anything else the k3s apps need on the LAN is declared per app with `lan.tcp` or `lan.udp` in
`apps.nix`. Forward 25565 and 6881 on the router to play or seed from outside.
