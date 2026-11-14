{ lib, headless, ... }:

{
  home.sessionVariables =
  {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  imports =
  [
    ./options.nix
    ./ui.nix
    ./lsp.nix
    ./ai.nix
    ./completion.nix
    ./formatting.nix
    ./treesitter.nix
    ./navigation.nix
    ./editing.nix
    ./git.nix
    ./diagnostics.nix
    ./ide.nix
    ./keymaps.nix
    ./packages.nix
  ]
  # servers: an editor, not an IDE
  ++ lib.optionals (!headless)
  [
    ./testing.nix
    ./debugging.nix
    ./cord.nix
  ];
}
