{
  config,
  inputs,
  lib,
  pkgs,
  subst,
  themeName,
  ...
}:

let
  p = config.themes.palette;

  theme = import ./recolor.nix { inherit lib subst; palette = p; };
  zenTheme = "${inputs.catppuccin-zen}/themes/Mocha/Mauve";
  # upstream's `background` shorthand on preferences buttons wipes Sine's icon images
  zenContent = pkgs.writeText "userContent.css" (lib.replaceStrings
    [ "background: #313244 !important;" ] [ "background-color: #313244 !important;" ]
    (builtins.readFile "${zenTheme}/userContent.css"));

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
  # on the toolbar, the rest in the extensions menu
  pinned = [ "bitwarden-password-manager" "darkreader" "duckduckgo-for-firefox" ];

  policies =
  {
    ExtensionSettings = lib.mapAttrs' (slug: id: lib.nameValuePair id
    {
      installation_mode = "force_installed";
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
      default_area = if lib.elem slug pinned then "navbar" else "menupanel";
    }) addons;
    # Bitwarden instead
    PasswordManagerEnabled = false;
  };

  # prefs both browsers share
  settings =
  {
    # Ctrl+Tab cycles through recently used tabs
    "browser.ctrlTab.sortByRecentlyUsed" = true;
    "browser.contentblocking.category" = "strict";
    # the "Default font" is the serif one, which Stylix sets to its serif
    "font.name.serif.x-western" = lib.mkForce config.stylix.fonts.monospace.name;
  };

  # DuckDuckGo, Startpage and nixpkgs; the browser's other built-ins hidden by id
  search = engines:
  {
    force = true;
    default = "ddg";
    privateDefault = "ddg";
    engines =
    {
      ddg.metaData.alias = "@dg";
      nixpkgs =
      {
        name = "Nix Packages";
        urls = [
        {
          template = "https://search.nixos.org/packages";
          params =
          [
            { name = "channel"; value = "unstable"; }
            { name = "query"; value = "{searchTerms}"; }
          ];
        }];
        icon = "${pkgs.nixos-icons}/share/icons/hicolor/64x64/apps/nix-snowflake.png";
        definedAliases = [ "@nx" ];
      };
      startpage =
      {
        name = "Startpage";
        urls = [ { template = "https://www.startpage.com/sp/search?query={searchTerms}"; } ];
        icon = "https://www.startpage.com/favicon.ico";
        definedAliases = [ "@sp" ];
      };
    } // engines;
  };
  hidden = ids: lib.genAttrs ids (_: { metaData.hidden = true; });

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
      # else it backs off on sites with their own dark mode, dropping the stylix colours
      detectDarkTheme = false;
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
  imports =
  [
    inputs.zen-browser.homeModules.beta
    ./sine.nix
  ];

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
      # Sine mod manager, pinned and non-updating
      sine.enable = true;
      search = search (hidden [ "google" "bing" "perplexity" "wikipedia" ]);
      # ids are the ones Zen made, so the cookies and open tabs carry over
      containersForce = true;
      containers =
      {
        HomeLab = { id = 6; color = "purple"; icon = "vacation"; };
        Uni = { id = 7; color = "blue"; icon = "fence"; };
        Personal = { id = 8; color = "yellow"; icon = "fingerprint"; };
      };
      # rewrites zen-sessions.jsonlz4, close Zen before switching
      spacesForce = true;
      spaces =
      {
        General = { id = "aaf6f51b-594d-4668-b351-774385971671"; position = 1000; icon = "🏠"; };
        Uni = { id = "ee7e508a-3519-45fa-bbcf-d616a7d6a558"; position = 2000; icon = "📚"; container = 7; };
        HomeLab = { id = "0a6214cd-b40f-4c10-9be5-c46030ec2aca"; position = 3000; icon = "🖥️"; container = 6; };
        Personal = { id = "bc2cccc5-0432-4574-9546-50b9f00f92f7"; position = 4000; icon = "📎"; container = 8; };
      };
      settings = settings //
      {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "zen.urlbar.behavior" = "float";
      };
      # upstream catppuccin/zen-browser recoloured, local overrides after it
      userChrome = theme.catppuccin "${zenTheme}/userChrome.css" + theme.override ./zen/userChrome.css;
      userContent = theme.catppuccin zenContent + theme.override ./zen/userContent.css;
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
      search = search (hidden [ "mojeek" "wikipedia" ]);
      settings = settings //
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
