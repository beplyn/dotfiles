{
  config,
  inputs,
  lib,
  ...
}:

let
  p = config.themes.palette;

  # AMO slug -> addon id; force-installed from AMO, auto-updating
  addons =
  {
    darkreader = "addon@darkreader.org";
    duckduckgo-for-firefox = "jid1-ZAdIEUB7XOzOJw@jetpack";
    libredirect = "7esoorv3@alefvanoon.anonaddy.me";
    duckduckgo-maps = "ddgm@de.de";
    ublock-origin = "uBlock0@raymondhill.net";
    bitwarden-password-manager = "{446900e4-71c2-419f-a6a7-df9c091e268b}";
    # by JobcenterTycoon
    cookie-auto-decline = "jobcentertycoon@gmail.com";
    augmented-steam = "{1be309c5-3e4f-4b99-927d-bb500eb4fa88}";
    steam-database = "firefox-extension@steamdb.info";
    protondb-for-steam = "{30280527-c46c-4e03-bb16-2e3ed94fa57c}";
    steamartworkhubessentials = "{bb53f7e1-a291-485a-88d7-2dca7b20c3a7}";
  };

  policies.ExtensionSettings = lib.mapAttrs' (slug: id: lib.nameValuePair id
  {
    installation_mode = "force_installed";
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
  }) addons;

  # Dark Reader follows the Stylix scheme
  extensions =
  {
    force = true;
    settings."addon@darkreader.org".settings =
    {
      # local storage only, sync would shadow these
      syncSettings = false;
      enabled = true;
      theme =
      {
        mode = 1;
        brightness = 100;
        contrast = 100;
        grayscale = 0;
        sepia = 0;
        useFont = false;
        fontFamily = "Open Sans";
        textStroke = 0;
        engine = "dynamicTheme";
        stylesheet = "";
        darkSchemeBackgroundColor = p.background;
        darkSchemeTextColor = p.foreground;
        lightSchemeBackgroundColor = p.foreground;
        lightSchemeTextColor = p.background;
        scrollbarColor = "auto";
        selectionColor = p.surface;
        styleSystemControls = false;
        lightColorScheme = "Default";
        darkColorScheme = "Default";
        immediateModify = false;
      };
    };
  };
in
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  # Zen: default browser
  programs.zen-browser =
  {
    enable = true;
    setAsDefaultBrowser = true;
    inherit policies;
    profiles.default =
    {
      id = 0;
      isDefault = true;
      inherit extensions;
    };
  };
  stylix.targets.zen-browser.profileNames = [ "default" ];

  # LibreWolf: throwaway, wipes everything on close
  programs.librewolf =
  {
    enable = true;
    inherit policies;
    # user.js is re-applied every launch
    profiles.default =
    {
      id = 0;
      isDefault = true;
      inherit extensions;
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
