{ config, ... }:

# which disk gets what, so the SSDs only see small or read-mostly writes:
#   sdc  Kingston 480G SSD  /, k3s, app state and databases (k3s.storage.state)
#   sdb  WD Green 120G SSD  regenerable read-mostly caches: thumbnails, metadata, ML models
#   sda  Barracuda 2T HDD   write-heavy throwaway data: transcodes, encoded video
#   sdd+sde  2x 6T HDD      btrfs raid1: music, video, photos, documents
# by label, so sdX reordering can't swap them; nofail so a dead disk doesn't stop boot
let
  st = config.k3s.storage;
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
  fileSystems.${st.bulk} = disk "tank" "btrfs" [ "compress=zstd:1" ];
  fileSystems.${st.cache} = disk "cache" "ext4" [ ];
  fileSystems.${st.scratch} = disk "scratch" "ext4" [ ];

  # every block is checksummed and mirrored: a scrub rewrites a rotten copy from the good one
  services.btrfs.autoScrub =
  {
    enable = true;
    fileSystems = [ st.bulk ];
    interval = "monthly";
  };

  # read-only daily snapshots against deletes and bad tag edits; video is replaceable
  services.snapper =
  {
    snapshotInterval = "daily";
    configs = builtins.listToAttrs (map (name:
    {
      inherit name;
      value =
      {
        SUBVOLUME = "${st.bulk}/${name}";
        TIMELINE_CREATE = true;
        TIMELINE_CLEANUP = true;
        TIMELINE_LIMIT_HOURLY = 0;
        TIMELINE_LIMIT_DAILY = 14;
        TIMELINE_LIMIT_WEEKLY = 8;
        TIMELINE_LIMIT_MONTHLY = 6;
        TIMELINE_LIMIT_YEARLY = 0;
      };
    }) [ "music" "photos" "documents" ]);
  };

  services.fstrim.enable = true;
  services.smartd.enable = true;
}
