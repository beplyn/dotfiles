{ lib, headless, ... }:

{
  imports =
  [
    ./git.nix
    ./jj.nix
    ./signing.nix
    ./nvim
    ./opencode
    ./openclaw.nix
  ]
  # servers: no compilers, no agents
  ++ lib.optionals (!headless)
  [
    ./toolchains.nix
    ./claude.nix
  ];
}
