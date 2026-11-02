{
  config,
  inputs,
  lib,
  subst,
  themeName,
  ...
}:

let
  p = config.themes.palette;

  theme = import ./recolor.nix { inherit lib subst; palette = p; };
  zenTheme = "${inputs.catppuccin-zen}/themes/Mocha/Mauve";

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
    catppuccin-web-file-icons = "{bbb880ce-43c9-47ae-b746-c3e0096c5b76}";
    vimium-ff = "{d7742d87-e61d-4b78-b8a1-b469842139fa}";
  };

  policies.ExtensionSettings = lib.mapAttrs' (slug: id: lib.nameValuePair id
  {
    installation_mode = "force_installed";
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
  }) addons;

  extensions =
  {
    force = true;
    # forge icons: mocha on catppuccin, single neutral colour on the others
    settings."{bbb880ce-43c9-47ae-b746-c3e0096c5b76}".settings =
    {
      flavor = "mocha";
      monochrome = themeName != "catppuccin";
    };
    # Dark Reader follows the Stylix scheme
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
      settings."toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      # upstream catppuccin/zen-browser recoloured, local overrides after it
      userChrome = theme.catppuccin "${zenTheme}/userChrome.css" + theme.override ./zen/userChrome.css;
      userContent = theme.catppuccin "${zenTheme}/userContent.css" + theme.override ./zen/userContent.css;
    };
  };
  home.file."${config.programs.zen-browser.profilesPath}/default/chrome/zen-logo-mocha.svg".text =
    theme.catppuccin "${zenTheme}/zen-logo-mocha.svg";
  stylix.targets.zen-browser =
  {
    profileNames = [ "default" ];
    # own userChrome/userContent above
    enableCss = false;
  };

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
      # upstream Glass-Firefox-Theme recoloured, local overrides after it
      userChrome = theme.glass "${inputs.glass-firefox}/chrome/userChrome.css" + theme.override ./glass/userChrome.css;
      userContent = theme.glass "${inputs.glass-firefox}/chrome/userContent.css" + theme.override ./glass/userContent.css;
      settings =
      {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        # see-through content area for the glass look
        "browser.tabs.allow_transparent_browser" = true;

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

  # Vimium keeps settings in sync storage only: restore this from its options page
  xdg.configFile."vimium/catppuccin.json".text = builtins.toJSON
  {
    settingsVersion = "2.4.2";
    userDefinedLinkHintCss =
      theme.catppuccin "${inputs.catppuccin-vimium}/themes/vimium/catppuccin-vimium-mocha.css"
      + theme.override ./vimium.css;
  };
}
