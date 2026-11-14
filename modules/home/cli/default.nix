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
    ./tools.nix
    ./forgejo.nix
    ./btop
  ]
  # servers: the essentials only
  ++ lib.optionals (!headless)
  [
    ./glow.nix
    ./fetch
    ./yazi.nix
    ./fun
    ./tldr.nix
    ./fastfetch.nix
    ./bottom.nix
    ./netspd
  ];
}
