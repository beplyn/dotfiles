{ config, ... }:

# pages cached locally, refreshed by a weekly timer
{
  services.tldr-update.enable = true;
  home.packages = [ config.services.tldr-update.package ];
}
