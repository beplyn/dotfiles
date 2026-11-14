{ lib, headless, ... }:

{
  imports =
  [
    ./ssh.nix
    ./bash
    ./bat.nix
    ./fzf.nix
    ./fd.nix
    ./eza.nix
    ./ripgrep.nix
    ./lazyclis.nix
    ./tmux.nix
    ./yazi.nix
    ./tools.nix
    ./forgejo.nix
    ./fastfetch.nix
    ./btop
    ./netspd
  ]
  # servers: the essentials only
  ++ lib.optionals (!headless)
  [
    ./glow.nix
    ./fetch
    ./fun
    ./tldr.nix
    ./bottom.nix
  ];
}
