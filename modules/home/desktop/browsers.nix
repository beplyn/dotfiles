{ inputs, ... }:

{
  imports = [ inputs.zen-browser.homeModules.beta ];

  # Zen: default browser
  programs.zen-browser =
  {
    enable = true;
    setAsDefaultBrowser = true;
    profiles.default =
    {
      id = 0;
      isDefault = true;
    };
  };
  stylix.targets.zen-browser.profileNames = [ "default" ];

  # LibreWolf: throwaway, wipes everything on close
  programs.librewolf =
  {
    enable = true;
    # user.js is re-applied every launch
    profiles.default =
    {
      id = 0;
      isDefault = true;
      settings =
      {
        "places.history.enabled" = false;
        "browser.formfill.enable" = false;
        "signon.rememberSignons" = false;

        "privacy.sanitize.sanitizeOnShutdown" = true;
        "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = true;
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;
        "privacy.clearOnShutdown_v2.cache" = true;
        "privacy.clearOnShutdown.history" = true;
        "privacy.clearOnShutdown.cookies" = true;
        "privacy.clearOnShutdown.offlineApps" = true;
        "privacy.clearOnShutdown.cache" = true;
        "privacy.clearOnShutdown.formdata" = true;
        "privacy.clearOnShutdown.downloads" = true;
        "privacy.clearOnShutdown.sessions" = true;
      };
    };
  };
  stylix.targets.librewolf.profileNames = [ "default" ];
}
