{
  programs.nixvim.plugins.conform-nvim =
  {
    enable = true;
    settings =
    {
      # nixfmt (RFC 166) forces `key = {`, which would undo the Allman braces
      # used across this repo. Nix buffers are skipped entirely, so neither
      # conform nor the LSP fallback (nixd defaults to nixfmt) touches them.
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
