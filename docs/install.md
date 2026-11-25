# Fresh install

Run `install.sh` from a NixOS installer or an existing NixOS system, as your normal user (not
root). It uses `sudo` where needed and asks on the terminal, so run it from a terminal.

```sh
# from a checkout
bash install.sh

# or without one; asks for the repo URL
curl -fsSL <url-to-install.sh> | bash
```

## What it does

1. **Repo.** Uses the checkout it runs from, or clones `REPO_URL` (or asks for it) into `~/<repo>`.
2. **Host and theme.** Lists `hosts/*` and the `themes` list in `flake.nix`.
3. **Values.** Asks for the values in [vars.md](vars.md) and saves them root-only to
   `/var/secrets/dotfiles/vars.toml`.
4. **Unfree software.** Asks once, then edits the host's `default.nix` to match.
5. **Hardware config.** Runs `nixos-generate-config` into `hosts/<host>/hardware.nix`. Hand-written
   settings are kept in `hardware-extra.nix`. A single LUKS root sets `encryption.device`; no LUKS
   disables the encryption module.
6. **/etc/nixos.** Links it to the repo.
7. **Build.** Evaluates `<host>-<theme>`, builds it, and installs it for the next boot.
8. **Next steps.** Lists the host secrets it needs, and offers a reboot.

If something fails before step 7, the host's `default.nix` and `hardware.nix` are put back.

## After the reboot

```sh
rebuild
```

`rebuild` sets up your GPG and SSH keys (upload them to the git host it names), asks for the host
secrets, and switches to the new system. See [rebuild.md](rebuild.md).

## Re-running

Safe to run again. It reuses the saved vars and an existing repo, and asks before regenerating
hardware config.
