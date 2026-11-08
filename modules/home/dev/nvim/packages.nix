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

  # classic icon theme (cord loads with defaults; this pins display.theme)
  programs.nixvim.extraConfigLua = "require('cord').setup({ display = { theme = 'classic' } });";
}
