{ lib, domain, ... }:

# shell history, e2e synced via beacon (sh.<domain>):
#   first:  atuin register -u <you> -e <email>; atuin key (save it)
#   others: atuin login -u <you>
#   then:   atuin import auto && atuin sync
{
  programs.atuin =
  {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    # Ctrl-R only: up keeps fish's prefix search and ble.sh's substring search
    flags = [ "--disable-up-arrow" ];
    settings =
    {
      sync_address = "https://sh.${domain}";
      auto_sync = true;
      sync_frequency = "5m";
      # the v2 record store: faster, and deletes sync too
      sync.records = true;
      update_check = false;
      style = "compact";
      inline_height = 20;
      # whole history, Ctrl-R again cycles to this session, directory and host
      filter_mode = "global";
      # Tab puts it on the line to edit, Enter runs it
      enter_accept = true;
    };
  };

  # Atuin takes Ctrl-R; fzf keeps Ctrl-T and Alt-C
  programs.fzf.historyWidget.command = lib.mkDefault "";
}
