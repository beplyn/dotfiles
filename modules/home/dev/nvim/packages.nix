{ pkgs, ... }:

{
  # telescope; the LSP servers come with lsp.nix
  programs.nixvim.extraPackages = with pkgs;
  [
    fd
    ripgrep
  ];

  # Discord Rich Presence (packaged in nixpkgs as cord-nvim)
  programs.nixvim.extraPlugins = [ pkgs.vimPlugins.cord-nvim ];
}
