{
  config,
  lib,
  pkgs,
  subst,
  username,
  email,
  forgejoHost,
  themeName,
  headless,
  ...
}:

let
  secrets = config.rebuild.secrets;

  # one `host_secret path what prefix kind units` call per secret
  secretLines = lib.concatStringsSep "\n" (lib.mapAttrsToList
    (path: s: "host_secret " + lib.escapeShellArgs
    [
      path
      s.description
      s.prefix
      (if s.file then "file" else "token")
      (toString s.restart)
    ])
    secrets);

  # rebuild [theme]: prompts for missing secrets and ~/.pfp, then switches to <host>-<theme>
  rebuild = pkgs.writeShellApplication
  {
    name = "rebuild";
    runtimeInputs = with pkgs;
    [
      git
      gnupg
      openssh
    ]
    ++ lib.optional config.forgejo.enable pkgs.forgejo-cli
    # ~/.pfp picker and file secrets
    ++ lib.optional (!headless || lib.any (s: s.file) (lib.attrValues secrets)) fzf
    # ~/.pfp and the greeter's wallpaper
    ++ lib.optional (!headless) imagemagick;
    text = subst
      {
        inherit username email forgejoHost themeName;
        hostName = config.networking.hostName;
        desktop = lib.boolToString (!headless);
        gated = lib.boolToString config.rebuildGate.enable;
        forgejo = lib.boolToString config.forgejo.enable;
        gate = lib.optionalString config.rebuildGate.enable "${config.rebuildGate.package}/bin/rebuild-gate";
        hostSecrets = secretLines;
      }
      (builtins.readFile ./rebuild.sh);
  };
in
{
  # root-only files outside the repo, asked for by rebuild when missing
  options.rebuild.secrets = lib.mkOption
  {
    type = lib.types.attrsOf (lib.types.submodule
    {
      options =
      {
        description = lib.mkOption
        {
          type = lib.types.str;
          description = "What to ask for.";
        };
        prefix = lib.mkOption
        {
          type = lib.types.str;
          default = "";
          example = "API_TOKEN=";
          description = "Written before the value, for env files.";
        };
        file = lib.mkOption
        {
          type = lib.types.bool;
          default = false;
          description = "Copy a local file (e.g. a PEM) instead of reading a pasted value.";
        };
        restart = lib.mkOption
        {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Units restarted after the secret is written.";
        };
      };
    });
    default = { };
    example = { "/var/secrets/foo.token".description = "Foo API token"; };
    description = "Secret files, keyed by absolute path, that rebuild prompts for.";
  };

  config =
  {
    environment.systemPackages = [ rebuild ];

    # /var/secrets and its subdirs stay root-only
    systemd.tmpfiles.rules = map (dir: "d ${dir} 0700 root root -")
      (lib.unique (lib.concatMap (path: [ "/var/secrets" (dirOf path) ])
        (lib.filter (lib.hasPrefix "/var/secrets/") (lib.attrNames secrets))));
  };
}
