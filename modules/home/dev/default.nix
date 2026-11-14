{ lib, headless, ... }:

{
  imports =
  [
    ./git.nix
    ./jj.nix
    ./signing.nix
    ./opencode
    ./openclaw.nix
  ]
  # servers: no compilers, no agents, plain vim
  ++ lib.optionals (!headless)
  [
    ./nvim
    ./toolchains.nix
    ./claude.nix
  ];

  # nixvim's defaultEditor sets these elsewhere
  home.sessionVariables = lib.mkIf headless
  {
    EDITOR = "vim";
    VISUAL = "vim";
  };
}
