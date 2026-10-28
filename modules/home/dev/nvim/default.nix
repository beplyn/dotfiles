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
    ./completion.nix
    ./formatting.nix
    ./treesitter.nix
    ./navigation.nix
    ./editing.nix
    ./git.nix
    ./diagnostics.nix
    ./ide.nix
    ./testing.nix
    ./debugging.nix
    ./keymaps.nix
    ./packages.nix
  ];
}
