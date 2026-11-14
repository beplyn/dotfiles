{ config, lib, pkgs, ... }:

# which disk gets what, so the SSDs only see small or read-mostly writes:
#   sdc  Kingston 480G SSD  /, k3s, app state and databases (k3s.storage.state)
#   sdb  WD Green 120G SSD  regenerable read-mostly caches: thumbnails, metadata, ML models
#   sda  Barracuda 2T HDD   write-heavy throwaway data: transcodes, encoded video
#   sdd  6T HDD "tank"      music, video, photos, documents
#   sde  6T HDD "backup"    btrbk copies of tank, daily k3s state backups
# by label, so sdX reordering can't swap them; nofail so a dead disk doesn't stop boot.
# hosts/beacon/README.md has the commands that make them
let
  st = config.k3s.storage;
  backup = config.k3s.backup.mount;

  disk = label: fsType: options:
  {
    device = "/dev/disk/by-label/${label}";
    inherit fsType;
    options =
    [
      "noatime"
      "nofail"
      "x-systemd.device-timeout=30s"
    ]
    ++ options;
  };
in
{
  # btrfs checksums every data and metadata block; on one disk a scrub finds rot (and
  # fixes metadata from its dup copy), the backup disk holds a good copy of the data
  fileSystems.${st.bulk} = disk "tank" "btrfs" [ "compress=zstd" ];
  fileSystems.${backup} = disk "backup" "btrfs" [ "compress=zstd" ];
  fileSystems.${st.cache} = disk "cache" "ext4" [ ];
  fileSystems.${st.scratch} = disk "scratch" "ext4" [ ];

  services.btrfs.autoScrub =
  {
    enable = true;
    fileSystems = [ st.bulk backup ];
    interval = "monthly";
  };

  # daily read-only snapshots of every tank subvolume, sent incrementally to the backup disk
  services.btrbk.instances.tank =
  {
    onCalendar = "daily";
    settings =
    {
      # runs as root below: beacon's sudo is wheel-only, so the module's sudo backend can't work
      backend = "btrfs-progs";
      timestamp_format = "long";
      # on tank: two weeks to undo a delete or a bad tag edit, plus the latest as the
      # parent of the next incremental send
      snapshot_preserve_min = "latest";
      snapshot_preserve = "14d";
      # on the backup disk
      target_preserve_min = "no";
      target_preserve = "14d 8w 6m";
      volume.${st.bulk} =
      {
        snapshot_dir = ".btrbk";
        target = "${backup}/tank";
        subvolume = lib.genAttrs [ "music" "video" "photos" "documents" ] (_: { });
      };
    };
  };

  systemd.services.btrbk-tank =
  {
    unitConfig =
    {
      WantsMountsFor = [ st.bulk backup ];
      OnFailure = config.k3s.onFailure;
    };
    serviceConfig =
    {
      User = lib.mkForce "root";
      Group = lib.mkForce "root";
      # fail loudly, not snapshot into an empty mountpoint on the system SSD
      ExecStartPre =
      [
        "${pkgs.util-linux}/bin/mountpoint -q ${st.bulk}"
        "${pkgs.util-linux}/bin/mountpoint -q ${backup}"
        "${pkgs.coreutils}/bin/mkdir -p ${st.bulk}/.btrbk ${backup}/tank"
      ];
    };
  };

  services.fstrim.enable = true;
  services.smartd.enable = true;
}
