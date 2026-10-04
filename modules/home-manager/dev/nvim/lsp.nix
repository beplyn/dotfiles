{
  programs.nixvim.plugins.lsp = {
    enable = true;
    servers = {
      clangd.enable = true;
      hls = {
        enable = true;
        installGhc = true;
      };
      rust_analyzer = {
        enable = true;
        installCargo = true;
        installRustc = true;
        installRustfmt = true;
      };
      zls.enable = true;
      fish_lsp.enable = true;
      bashls.enable = true;
      csharp_ls.enable = true;
      gopls.enable = true;
      marksman.enable = true;
      nixd.enable = true;
    };
  };
}
