{ lib, headless, ... }:

{
  imports =
  [
    ./git
    ./jj.nix
    ./signing.nix
    ./opencode
    ./openclaw.nix
    ./claude.nix
  ]
  # servers: no compilers or editor plugins, plain vim
  ++ lib.optionals (!headless)
  [
    ./nvim
    ./toolchains.nix
  ];

  # nixvim's defaultEditor sets these elsewhere
  home.sessionVariables = lib.mkIf headless
  {
    EDITOR = "vim";
    VISUAL = "vim";
  };
}
