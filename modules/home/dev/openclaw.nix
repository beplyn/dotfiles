{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  llm = osConfig.llm;
  searxUrl = "http://127.0.0.1:${toString llm.searxPort}";
in
lib.mkIf llm.enable
{
  # agent on local Ollama; SearXNG for web_search
  home.packages = [ pkgs.openclaw ];

  home.sessionVariables =
  {
    # config is a store symlink, nix mode keeps openclaw from rewriting it
    OPENCLAW_NIX_MODE = "1";
    OLLAMA_API_KEY = "ollama-local";
    SEARXNG_BASE_URL = searxUrl;
  };

  # searxng ships in the package but not as a bundled plugin
  home.file.".openclaw/extensions/searxng".source = "${pkgs.openclaw}/lib/openclaw/extensions/searxng";

  home.file.".openclaw/openclaw.json".text = builtins.toJSON
  {
    models.providers.ollama =
    {
      # native api: /v1 breaks tool calling
      baseUrl = "http://127.0.0.1:${toString osConfig.services.ollama.port}";
      apiKey = "ollama-local";
      api = "ollama";
      models =
      [
        {
          id = llm.model;
          name = llm.model;
          input = [ "text" ];
          contextTokens = llm.contextLength;
          params.num_ctx = llm.contextLength;
        }
      ];
    };
    agents.defaults.model.primary = "ollama/${llm.model}";
    tools.web.search =
    {
      enabled = true;
      provider = "searxng";
    };
    plugins.allow =
    [
      "ollama"
      "searxng"
    ];
    plugins.entries.searxng =
    {
      enabled = true;
      config.webSearch.baseUrl = searxUrl;
    };
  };
}
