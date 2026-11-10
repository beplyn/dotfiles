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
    # search before guessing
    context = ./rules.md;
    # stylix still sets tui.json, which OpenCode 2 ignores; the theme goes in cli.json
    tui = lib.mkForce { };
    cli.theme.name = "stylix";
    settings =
    {
      model = "ollama/${llm.model}";
      # same model: no second big model next to it (OLLAMA_MAX_LOADED_MODELS)
      small_model = "ollama/${llm.model}";
      share = "disabled";
      autoupdate = false;
      provider.ollama =
      {
        npm = "@ai-sdk/openai-compatible";
        name = "Ollama (local)";
        options.baseURL = "http://127.0.0.1:${toString osConfig.services.ollama.port}/v1";
        models = lib.genAttrs llm.models (m:
        {
          name = m;
          tools = true;
          limit =
          {
            context = llm.contextLength;
            output = 16384;
          };
        });
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
