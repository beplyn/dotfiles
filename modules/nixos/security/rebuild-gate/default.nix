{
  config,
  lib,
  pkgs,
  subst,
  username,
  themeName,
  themes,
  ...
}:

# switches only to commits signed by the master key, an unsigned one only on a TOTP code;
# sudo and polkit need password + the same TOTP, so they can't go around it.
# The master key and TOTP seed stay root-only on the host, never in the repo: `sudo rebuild-gate init`.
let
  cfg = config.rebuildGate;

  runtimeInputs = with pkgs;
  [
    coreutils
    gawk
    gnugrep
    util-linux
    git
    gnupg
    openssh
    oath-toolkit
    google-authenticator
    config.nix.package
    config.system.build.nixos-rebuild
  ];

  gate = pkgs.writeShellApplication
  {
    name = "rebuild-gate";
    inherit runtimeInputs;
    text = subst
      {
        inherit username themeName;
        inherit (cfg) keysDir stateDir totpSecret;
        inherit (cfg.autoDeploy) remote branch;
        hostName = config.networking.hostName;
        themes = lib.escapeShellArgs themes;
        secrets = lib.escapeShellArgs (lib.attrNames config.rebuild.secrets);
        # the system profile after its own inputs, for whatever nixos-rebuild calls
        path = "${lib.makeBinPath runtimeInputs}:/run/current-system/sw/bin";
      }
      (builtins.readFile ./gate.sh);
  };
  gateBin = "${gate}/bin/rebuild-gate";
in
{
  options.rebuildGate =
  {
    enable = lib.mkEnableOption "switching only to commits signed by the master key, or on a TOTP code";

    package = lib.mkOption
    {
      type = lib.types.package;
      default = gate;
      readOnly = true;
      internal = true;
      description = "The rebuild-gate script, for rebuild.";
    };

    keysDir = lib.mkOption
    {
      type = lib.types.str;
      default = "/var/lib/rebuild-gate/keys";
      description = "Root-only home of the master public key (allowed_signers or a GPG keyring), pasted at init.";
    };

    stateDir = lib.mkOption
    {
      type = lib.types.str;
      default = "/var/lib/rebuild-gate";
      description = "Root-only bare repo the gate builds from.";
    };

    totpSecret = lib.mkOption
    {
      type = lib.types.str;
      default = "/var/secrets/rebuild-totp.secret";
      description = "Root-only TOTP seed (google-authenticator format), shared by the gate, sudo and polkit.";
    };

    allowUnenrolled = lib.mkOption
    {
      type = lib.types.bool;
      default = true;
      description = ''
        sudo on password alone while there is no TOTP seed, so the first switch can't lock it.
        Only root can remove the seed; set false once enrolled to make a missing one fatal.
      '';
    };

    autoDeploy =
    {
      enable = lib.mkEnableOption "a timer that fetches the remote and deploys new signed commits";

      remote = lib.mkOption
      {
        type = lib.types.str;
        default = "";
        example = "https://codeberg.org/user/dotfiles.git";
        description = "Repository to fetch; public, the timer has no credentials.";
      };

      branch = lib.mkOption
      {
        type = lib.types.str;
        default = "master";
        description = "Branch whose tip gets deployed.";
      };

      interval = lib.mkOption
      {
        type = lib.types.str;
        default = "*:0/15";
        description = "systemd OnCalendar for the fetch.";
      };
    };
  };

  config = lib.mkIf cfg.enable
  {
    assertions =
    [
      {
        assertion = !cfg.autoDeploy.enable || cfg.autoDeploy.remote != "";
        message = "rebuildGate.autoDeploy needs a remote";
      }
    ];

    environment.systemPackages = [ gate ];

    # password, then TOTP (unix-early, google_authenticator required, unix)
    security.pam.services = lib.genAttrs [ "sudo" "polkit-1" ] (_:
    {
      googleAuthenticator =
      {
        enable = true;
        allowNullOTP = cfg.allowUnenrolled;
      };
      # root-owned, so a user shell can't swap in its own seed
      rules.auth.google_authenticator.settings =
      {
        secret = cfg.totpSecret;
        user = "root";
      };
    });

    security.sudo =
    {
      wheelNeedsPassword = true;
      execWheelOnly = true;
      # after wheel's rule, so these win; the gate checks its own arguments
      extraRules =
      [
        {
          users = [ username ];
          runAs = "root";
          commands =
          [
            {
              command = "${gateBin} state";
              options = [ "NOPASSWD" ];
            }
            {
              command = "${gateBin} deploy *";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    };

    systemd.tmpfiles.rules =
    [
      "d ${cfg.stateDir} 0700 root root -"
      "d ${cfg.keysDir} 0700 root root -"
      "d ${dirOf cfg.totpSecret} 0700 root root -"
    ];

    systemd.services.rebuild-gate-fetch = lib.mkIf cfg.autoDeploy.enable
    {
      description = "Deploy new commits signed by the master key";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      # it switches the system it runs in
      restartIfChanged = false;
      unitConfig.X-StopOnRemoval = false;
      environment = config.networking.proxy.envVars;
      serviceConfig =
      {
        Type = "oneshot";
        ExecStart = "${gateBin} fetch";
      };
    };

    systemd.timers.rebuild-gate-fetch = lib.mkIf cfg.autoDeploy.enable
    {
      wantedBy = [ "timers.target" ];
      timerConfig =
      {
        OnCalendar = cfg.autoDeploy.interval;
        Persistent = true;
        RandomizedDelaySec = "1min";
      };
    };
  };
}
