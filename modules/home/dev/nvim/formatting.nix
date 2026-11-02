{
  # clangd formats C/C++ with the nearest .clang-format; this is the default for anything under ~
  home.file.".clang-format".text = ''
    BasedOnStyle: LLVM
    BreakBeforeBraces: Allman
  '';

  programs.nixvim.plugins.conform-nvim =
  {
    enable = true;
    settings =
    {
      # skip nix: nixfmt breaks the Allman braces
      format_on_save.__raw = ''
        function(bufnr)
          if vim.bo[bufnr].filetype == "nix" then
            return
          end
          return { lsp_fallback = true, timeout_ms = 500 }
        end
      '';
    };
  };
}
