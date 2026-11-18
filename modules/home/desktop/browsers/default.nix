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
    # open and save dialogs through the portal, which hands them to Nautilus
    "widget.use-xdg-desktop-portal.file-picker" = 1;
    # ask where to save every download
    "browser.download.useDownloadDir" = false;
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

  # ids from Zen, so cookies and tabs carry over
  containers =
  {
    HomeLab = { id = 6; color = "purple"; icon = "vacation"; };
    Uni = { id = 7; color = "blue"; icon = "fence"; };
    Personal = { id = 8; color = "yellow"; icon = "fingerprint"; };
  };
  # Zen spaces = Floorp workspaces; glyph is the Floorp icon
  spaces =
  {
    General = { id = "aaf6f51b-594d-4668-b351-774385971671"; position = 1000; icon = "🏠"; glyph = "compass"; };
    Uni = { id = "ee7e508a-3519-45fa-bbcf-d616a7d6a558"; position = 2000; icon = "📚"; glyph = "book"; container = 7; };
    HomeLab = { id = "0a6214cd-b40f-4c10-9be5-c46030ec2aca"; position = 3000; icon = "🖥️"; glyph = "network"; container = 6; };
    Personal = { id = "bc2cccc5-0432-4574-9546-50b9f00f92f7"; position = 4000; icon = "📎"; glyph = "user"; container = 8; };
  };

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
    ./tor.nix
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
      containersForce = true;
      inherit containers;
      # rewrites zen-sessions.jsonlz4, close Zen before switching
      spacesForce = true;
      spaces = lib.mapAttrs (_: space: removeAttrs space [ "glyph" ]) spaces;
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

  # Floorp: made to look like Zen, same containers and spaces
  programs.floorp =
  {
    enable = true;
    inherit policies;
    profiles.default =
    {
      id = 0;
      isDefault = true;
      inherit extensions containers;
      containersForce = true;
      search = search (hidden [ "google" "bing" "perplexity" "wikipedia" ]);
      settings = settings //
      {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # Firefox's vertical tabs, always open
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;
        "sidebar.visibility" = "always-show";
        "sidebar.main.tools" = "bookmarks,history";
        "sidebar.verticalTabs.dragToPinPromo.dismissed" = true;
        "browser.toolbars.bookmarks.visibility" = "never";
        # Zen is the default
        "browser.shell.checkDefaultBrowser" = false;

        # the tab strip is hidden, so workspaces go on the nav bar
        "browser.uiCustomization.state" =
          let
            # addon id -> its toolbar button
            widget = slug: lib.toLower (lib.replaceStrings [ "{" "}" "@" "." ] [ "_" "_" "_" "_" ] addons.${slug}) + "-browser-action";
          in
          builtins.toJSON
          {
            placements =
            {
              nav-bar =
              [
                "back-button" "forward-button" "stop-reload-button" "workspaces-toolbar-button"
                "urlbar-container" "vertical-spacer" "zen-mode-button" "unified-extensions-button"
              ] ++ map widget pinned;
              unified-extensions-area = map widget (lib.subtractLists pinned (lib.attrNames addons));
              TabsToolbar = [ ];
              vertical-tabs = [ "tabbrowser-tabs" ];
              toolbar-menubar = [ "menubar-items" ];
              PersonalToolbar = [ "personal-bookmarks" ];
              nora-statusbar = [ "screenshot-button" "fullscreen-button" "status-text" ];
              widget-overflow-fixed-list = [ ];
            };
            # marked seen, else Floorp adds them back
            seen =
            [
              "developer-button" "profile-manager-button" "undo-closed-tab" "ai-window-toggle"
              "smartwindow-group-tabs-button" "reset-pbm-toolbar-button" "ipprotection-button"
              "zen-mode-button" "workspaces-toolbar-button"
            ] ++ map widget (lib.attrNames addons);
            currentVersion = 28;
            newElementCount = 0;
          };

        # merged over Floorp's defaults; Proton base, the look is userChrome
        "floorp.design.configs" = builtins.toJSON
        {
          globalConfigs = { userInterface = "proton"; faviconColor = false; appliedUserJs = ""; };
          tabbar = { tabbarStyle = "vertical"; tabbarPosition = "default"; };
          uiCustomization.chromeExtras.hiddenSidebarHeader = true;
        };

        # no web panels in Zen
        "floorp.panelSidebar.enabled" = false;

        # reset each launch like Zen's spacesForce; tabs follow by id
        "floorp.workspaces.enabled" = true;
        "floorp.workspaces.v4.store" =
          let
            ordered = lib.sortOn (s: s.position) (lib.attrValues (lib.mapAttrs (name: s: s // { inherit name; }) spaces));
            isDefault = s: s.id == spaces.General.id;
          in
          builtins.toJSON
          {
            defaultID = spaces.General.id;
            # a Map in Floorp: [id, workspace] pairs
            data = map (s:
            [
              s.id
              {
                inherit (s) name;
                userContextId = s.container or 0;
                isDefault = isDefault s;
                isSelected = isDefault s;
                icon = "floorp-icon:v1:${s.glyph}";
              }
            ]) ordered;
            order = map (s: s.id) ordered;
          };

        # Floorp's Zen mode on Zen's compact-mode key, Ctrl+Alt+C
        "floorp.keyboardshortcut.config" = builtins.toJSON
        {
          schemaVersion = 2;
          enabled = true;
          shortcuts =
          {
            floorp-toggle-command-palette =
            {
              key = "F2";
              modifiers = { alt = false; ctrl = false; meta = false; shift = false; };
              action = "floorp-toggle-command-palette";
            };
            floorp-toggle-zen-mode =
            {
              key = "KeyC";
              modifiers = { alt = true; ctrl = true; meta = false; shift = false; };
              action = "floorp-toggle-zen-mode";
            };
          };
        };
      };
      userChrome = theme.override ./floorp/userChrome.css;
      userContent = theme.override ./floorp/userContent.css;
    };
  };
  stylix.targets.floorp.profileNames = [ "default" ];

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
