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
  # Terminal coding agent wired to the local Ollama model. Built-in tools
  # cover files, shell and fetching pages (webfetch); the SearXNG MCP server
  # adds web search, so the agent can find pages and then crawl them.
  programs.opencode = lib.mkIf llm.enable
  {
    enable = true;
    settings =
    {
      model = "ollama/${llm.model}";
      small_model = "ollama/${llm.model}";
      share = "disabled";
      autoupdate = false;
      provider.ollama =
      {
        npm = "@ai-sdk/openai-compatible";
        name = "Ollama (local)";
        options.baseURL = "http://127.0.0.1:11434/v1";
        models.${llm.model} =
        {
          name = "Qwen3.8 27B";
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
