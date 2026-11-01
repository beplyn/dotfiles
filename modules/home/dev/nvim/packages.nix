{ pkgs, ... }:

{
  # telescope; the LSP servers come with lsp.nix
  programs.nixvim.extraPackages = with pkgs;
  [
    fd
    ripgrep
  ];
}
