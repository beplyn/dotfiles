# Repo layout

```
flake.nix            inputs, and one nixosConfiguration per <host>-<theme>
install.sh           first install (see install.md)
lib/                 mkHost.nix (builds a host), subst.nix (@name@ templating)
hosts/<host>/        one directory per machine: default.nix, hardware, network, storage
modules/
  nixos/             system modules: base, desktop, security, services (k3s, pelican, ...)
  home/              Home Manager: cli, desktop, dev
  theme/             palette, stylix, wallpaper
users/me/            Home Manager entry point for your user
scripts/wireguard/   key helpers for the wg0 mesh
vars/                placeholder template for your values (see vars.md)
docs/                these guides
```

## How hosts are built

`flake.nix` lists the directories in `hosts/` and the `themes` list. Every combination becomes a
`nixosConfigurations.<host>-<theme>`, so adding a host or a theme is a directory or a list entry.

`lib/mkHost.nix` gives every module the same arguments from the vars file (`username`, `email`,
`domain`, `repo`, `lan`, `wgKeys`) and the host name, theme and `headless` flag.

## Adaptive options

Modules read values from options, not hardcoded names. The main ones:

| Option                    | Set in                        | Used for                                          |
|---------------------------|-------------------------------|---------------------------------------------------|
| `proxy.domain`            | `hosts/beacon/default.nix`    | Every public hostname (`<name>.<domain>`)         |
| `proxy.hosts.<name>`      | Modules (for example pelican) | An nginx vhost, with its own TLS and auth        |
| `k3s.apps`                | `hosts/beacon/default.nix`    | Which apps from `apps.nix` run                    |
| `k3s.storage.*`           | `hosts/beacon/storage.nix`    | Mount points for the app data disks              |
| `k3s.lanAddress`          | `hosts/beacon/default.nix`    | AdGuard's LAN DNS mapping                        |
| `rebuild.secrets.<path>`  | Any module                    | A root-only file that `rebuild` asks for          |
| `rebuild.auto.*`          | `hosts/beacon/default.nix`    | Auto-rebuild URL, branch and interval             |
| `wireguard.peers`         | `hosts/<host>/default.nix`    | WireGuard peers; empty keys are left out         |
| `pelican.enable`          | `hosts/beacon/default.nix`    | Wings, mc-router and the Minecraft sync          |
| `hosts/<name>/meta.nix`   | Per host                      | `headless` (no GUI) and `staticLan` (asks for lan.* vars) |

## Adding a host

1. `mkdir hosts/<name>` with a `default.nix` that sets `networking.hostName`. Add a `meta.nix` only if it
   is headless or has a static LAN address; the flake and install script read it, nothing else needs edits.
2. Run `install.sh` on the machine and pick the new host. It generates `hardware.nix`.

## Adding a k3s app

1. Add its manifest to `modules/nixos/services/k3s/manifests/<app>.yaml`.
2. Add an entry to `apps` in `modules/nixos/services/k3s/apps.nix` (subdomain, port, secrets, dirs).
3. Add the name to `k3s.apps` in `hosts/beacon/default.nix`.
4. If it uses Pocket ID, see [pocket-id.md](pocket-id.md).
