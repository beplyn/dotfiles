{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.llm;
  searxPort = 8888;
in
{
  options.llm =
  {
    enable = lib.mkEnableOption "a local coding model (Ollama on ROCm) with SearXNG web search";

    model = lib.mkOption
    {
      type = lib.types.str;
      # Dense 27B, ~18 GB at Q4_K_M: leaves room on a 24 GB card for the KV
      # cache.
      default = "qwen3.8:27b";
      description = "Ollama model tag to pull and serve.";
    };

    contextLength = lib.mkOption
    {
      type = lib.types.int;
      default = 65536;
      description = "Default context window; agentic coding needs at least 32k.";
    };

    searxPort = lib.mkOption
    {
      type = lib.types.port;
      default = searxPort;
      readOnly = true;
      description = "Port of the local SearXNG instance (localhost only).";
    };
  };

  config = lib.mkIf cfg.enable
  {
    services.ollama =
    {
      enable = true;
      # The 7900 XTX (gfx1100) is a supported ROCm target, so no
      # rocmOverrideGfx is needed.
      package = pkgs.ollama-rocm;
      loadModels = [ cfg.model ];
      environmentVariables =
      {
        OLLAMA_CONTEXT_LENGTH = toString cfg.contextLength;
        # Flash attention plus a q8 KV cache halves cache memory with no
        # measurable quality loss; needed to fit 64k context next to the model.
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
        # One model at a time: two 27B models do not fit in 24 GB.
        OLLAMA_MAX_LOADED_MODELS = "1";
        OLLAMA_NUM_PARALLEL = "1";
        OLLAMA_KEEP_ALIVE = "30m";
      };
    };

    # Metasearch backend for the agent's web search tool. Bound to localhost;
    # the JSON output format is what MCP clients query.
    services.searx =
    {
      enable = true;
      package = pkgs.searxng;
      environmentFile = "/var/lib/searx-secret/env";
      settings =
      {
        server =
        {
          port = searxPort;
          bind_address = "127.0.0.1";
          secret_key = "$SEARX_SECRET_KEY";
          limiter = false;
        };
        search.formats =
        [
          "html"
          "json"
        ];
      };
    };

    # The secret only signs cookies and the image proxy, but it should not
    # live in the world-readable store: generate it once on first boot.
    systemd.services.searx-secret =
    {
      wantedBy = [ "searx-init.service" ];
      before = [ "searx-init.service" ];
      serviceConfig =
      {
        Type = "oneshot";
        StateDirectory = "searx-secret";
        StateDirectoryMode = "0700";
        UMask = "0077";
      };
      script = ''
        f=/var/lib/searx-secret/env
        [ -s "$f" ] || echo "SEARX_SECRET_KEY=$(${lib.getExe pkgs.openssl} rand -hex 32)" > "$f"
      '';
    };
    systemd.services.searx-init =
    {
      requires = [ "searx-secret.service" ];
      after = [ "searx-secret.service" ];
    };
  };
}
