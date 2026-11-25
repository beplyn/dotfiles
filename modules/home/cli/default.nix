{ lib, headless, ... }:

{
  imports =
  [
    ./ssh.nix
    ./atuin.nix
    ./bat.nix
    ./fzf.nix
    ./fd.nix
    ./eza.nix
    ./ripgrep.nix
    ./lazyclis.nix
    ./tmux.nix
    ./zsh
    ./yazi.nix
    ./tools.nix
    ./fastfetch.nix
    ./btop
    ./netspd
  ]
  # servers: the essentials only
  ++ lib.optionals (!headless)
  [
    ./glow.nix
    ./fun
    ./tldr.nix
    ./bottom.nix
  ];
}
