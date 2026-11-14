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
  auto = config.rebuild.auto;
  hostName = config.networking.hostName;

  autoRebuild = pkgs.writeShellApplication
  {
    name = "auto-rebuild";
    runtimeInputs = with pkgs;
    [
      coreutils
      gitMinimal
      config.nix.package
      config.system.build.nixos-rebuild
    ];
    text = builtins.readFile ./auto-rebuild.sh;
  };

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
    # ~/.pfp picker and file secrets
    ++ lib.optional (!headless || lib.any (s: s.file) (lib.attrValues secrets)) fzf
    # ~/.pfp and the greeter's wallpaper
    ++ lib.optional (!headless) imagemagick;
    text = subst
      {
        inherit username email forgejoHost themeName;
        inherit hostName;
        desktop = lib.boolToString (!headless);
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

  # rebuild.secrets aren't asked for: they have to be there already
  options.rebuild.auto =
  {
    enable = lib.mkEnableOption "switching to every new commit on rebuild.auto.branch, without a prompt";

    url = lib.mkOption
    {
      type = lib.types.str;
      default = "https://${forgejoHost}/${username}/dotfiles.git";
      description = "Repo polled for the branch, over https so it needs no key.";
    };

    branch = lib.mkOption
    {
      type = lib.types.str;
      default = hostName;
      description = "Branch whose newest commit this host switches to; whoever can push to it is root here.";
    };

    interval = lib.mkOption
    {
      type = lib.types.str;
      default = "5min";
      description = "How long after one check ends the next one starts.";
    };
  };

  config =
  {
    environment.systemPackages = [ rebuild ];

    # a switch would otherwise stop the unit doing the switch
    systemd.services.auto-rebuild = lib.mkIf auto.enable
    {
      description = "Switch to the newest commit on ${auto.branch}";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;
      # the host's failure alerts, where there are any (ntfy on k3s)
      unitConfig.OnFailure = config.k3s.onFailure or [ ];
      environment.HOME = "/root";
      serviceConfig =
      {
        Type = "oneshot";
        StateDirectory = "auto-rebuild";
        ExecStart = lib.escapeShellArgs
        [
          (lib.getExe autoRebuild)
          auto.url
          auto.branch
          "${hostName}-${themeName}"
        ];
      };
    };

    systemd.timers.auto-rebuild = lib.mkIf auto.enable
    {
      wantedBy = [ "timers.target" ];
      timerConfig =
      {
        OnBootSec = "2min";
        OnUnitInactiveSec = auto.interval;
      };
    };

    # /var/secrets and its subdirs stay root-only
    systemd.tmpfiles.rules = map (dir: "d ${dir} 0700 root root -")
      (lib.unique (lib.concatMap (path: [ "/var/secrets" (dirOf path) ])
        (lib.filter (lib.hasPrefix "/var/secrets/") (lib.attrNames secrets))));
  };
}
