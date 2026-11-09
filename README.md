# dotfiles

NixOS and Home Manager configuration managed as a flake. The configuration combines reusable modules with per-host hardware and settings, and generates a configuration for every supported host/theme pair.

## Features

- Declarative NixOS and Home Manager setup
- Host-specific hardware and system configuration
- Shared modules for common services and desktop features
- Stylix-based theming
- Themes: `catppuccin`, `gruvbox`, and `nord`
- Interactive installation script for fresh NixOS installations

## Hosts

- `anvil`
- `beacon` (headless)
- `compass`
- `shulker`

Configuration names use the format `<host>-<theme>`, for example `anvil-catppuccin`.

## Installation

The installer requires a NixOS system with `sudo`. Run it as your normal user, not as root:

```sh
curl -fsSL https://codeberg.org/beplyn/dotfiles/raw/branch/main/install.sh | bash
```

The script will:

1. Clone or reuse the repository in `~/dotfiles`.
2. Ask you to select a host and theme.
3. Optionally generate the machine's hardware configuration.
4. Link `/etc/nixos` to the checkout.
5. Build and install the selected configuration for the next boot.

Hardware configuration contains machine-specific filesystem and device information. Review the generated changes before committing them.

To install from this GitHub mirror instead, set `REPO_URL`:

```sh
REPO_URL=https://github.com/sbalazs222/dotfiles.git \\
  curl -fsSL https://codeberg.org/beplyn/dotfiles/raw/branch/main/install.sh | bash
```

## Manual usage

List the available configurations:

```sh
nix flake show
```

Build a configuration without switching:

```sh
nix build .#nixosConfigurations.anvil-catppuccin.config.system.build.toplevel
```

Rebuild the running system from the checkout:

```sh
sudo nixos-rebuild switch --flake .#anvil-catppuccin
```

Replace `anvil-catppuccin` with the host/theme combination for the machine.

## Repository layout

- `flake.nix` — flake inputs and generated NixOS configurations
- `hosts/` — host-specific system and hardware configuration
- `modules/` — reusable NixOS, Home Manager, and theme modules
- `users/` — user configuration
- `lib/` — helpers used to construct hosts
- `install.sh` — interactive installer

## License

See [LICENSE](LICENSE).
