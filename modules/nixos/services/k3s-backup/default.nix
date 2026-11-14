{
  config,
  lib,
  pkgs,
  ...
}:

# daily consistent copy of everything the apps keep on the system SSD, plus the cluster itself,
# as dated read-only btrfs snapshots on the backup disk
let
  cfg = config.k3s.backup;
  pgSpec = pkgs.writeText "k3s-backup-postgres" (lib.concatMapStrings
    (db: "${db.namespace} ${db.deployment} ${db.user}\n")
    config.k3s.postgres);
in
{
  options.k3s.backup =
  {
    enable = lib.mkEnableOption "daily backups of the k3s app state and cluster";

    mount = lib.mkOption
    {
      type = lib.types.str;
      default = "/srv/backup";
      description = "Backup filesystem (btrfs); nothing runs unless it is mounted.";
    };

    target = lib.mkOption
    {
      type = lib.types.str;
      default = "${cfg.mount}/k3s-state";
      defaultText = lib.literalExpression ''"''${config.k3s.backup.mount}/k3s-state"'';
      description = "Where the copy and its dated snapshots go.";
    };

    keep = lib.mkOption
    {
      type = lib.types.ints.positive;
      default = 14;
      description = "Daily snapshots to keep.";
    };
  };

  config = lib.mkIf (config.k3s.enable && cfg.enable)
  {
    systemd.services.k3s-backup =
    {
      description = "Back up k3s app state and cluster";
      wants = [ "k3s.service" ];
      after = [ "k3s.service" ];
      unitConfig =
      {
        WantsMountsFor = [ cfg.mount ];
        OnFailure = config.k3s.onFailure;
      };
      path = with pkgs;
      [
        config.services.k3s.package
        btrfs-progs
        coreutils
        findutils
        gnused
        rsync
        sqlite
        util-linux
        zstd
      ];
      serviceConfig =
      {
        Type = "oneshot";
        UMask = "0077";
        Nice = 10;
        IOSchedulingClass = "idle";
        ExecStart = lib.escapeShellArgs
        [
          "${pkgs.bash}/bin/bash"
          ./backup.sh
          cfg.mount
          cfg.target
          config.k3s.storage.state
          pgSpec
          (toString cfg.keep)
        ];
      };
    };

    systemd.timers.k3s-backup =
    {
      wantedBy = [ "timers.target" ];
      timerConfig =
      {
        # the apps are quietest at night
        OnCalendar = "*-*-* 03:30:00";
        RandomizedDelaySec = "15min";
        Persistent = true;
      };
    };
  };
}
