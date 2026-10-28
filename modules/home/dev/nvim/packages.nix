{ pkgs, ... }:

{
  programs.nixvim.extraPackages = with pkgs;
  [
    fd
    clang-tools
    rust-analyzer
    rustfmt
    zls
    fish-lsp
    bash-language-server
    csharp-ls
    gopls
    haskell-language-server
    marksman
    nixfmt
    ripgrep
  ];
}
