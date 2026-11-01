{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  llm = osConfig.llm;
in
{
  # coding agent on local Ollama; SearXNG MCP for web search
  programs.opencode = lib.mkIf llm.enable
  {
    enable = true;
    settings =
    {
      model = "ollama/${llm.model}";
      # same model: one is loaded at a time (OLLAMA_MAX_LOADED_MODELS)
      small_model = "ollama/${llm.model}";
      share = "disabled";
      autoupdate = false;
      provider.ollama =
      {
        npm = "@ai-sdk/openai-compatible";
        name = "Ollama (local)";
        options.baseURL = "http://127.0.0.1:${toString osConfig.services.ollama.port}/v1";
        models.${llm.model} =
        {
          name = llm.model;
          tools = true;
          limit =
          {
            context = llm.contextLength;
            output = 16384;
          };
        };
      };
      mcp.searxng =
      {
        type = "local";
        command = [ (lib.getExe pkgs.mcp-searxng) ];
        environment.SEARXNG_URL = "http://127.0.0.1:${toString llm.searxPort}";
        enabled = true;
      };
    };
  };
}
