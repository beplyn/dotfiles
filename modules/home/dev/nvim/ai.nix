{ lib, osConfig, ... }:

let
  llm = osConfig.llm;
in
{
  # FIM completions from local Ollama via lsp-ai, shown by cmp's nvim_lsp source
  programs.nixvim.plugins.lsp.servers.lsp_ai = lib.mkIf llm.enable
  {
    enable = true;
    # lspconfig ships an empty list
    filetypes =
    [
      "c"
      "cpp"
      "cs"
      "rust"
      "zig"
      "go"
      "haskell"
      "nix"
      "lua"
      "python"
      "sh"
      "bash"
      "fish"
      "javascript"
      "typescript"
      "css"
      "html"
      "json"
      "toml"
      "yaml"
      "markdown"
    ];
    extraOptions.init_options =
    {
      # empty attrsets get stripped, lsp-ai needs the key
      memory.file_store.__raw = "vim.empty_dict()";
      models.ollama =
      {
        type = "ollama";
        model = llm.completionModel;
        generate_endpoint = "http://127.0.0.1:${toString osConfig.services.ollama.port}/api/generate";
        max_requests_per_second = 4;
      };
      completion =
      {
        model = "ollama";
        parameters =
        {
          max_context = 2048;
          # qwen2.5-coder fim tokens
          fim =
          {
            start = "<|fim_prefix|>";
            middle = "<|fim_suffix|>";
            end = "<|fim_middle|>";
          };
          options =
          {
            num_predict = 48;
            # not the 64k server default: keeps it small next to the agent model
            num_ctx = 4096;
            temperature = 0.2;
          };
          keep_alive = "30m";
        };
      };
    };
  };
}
