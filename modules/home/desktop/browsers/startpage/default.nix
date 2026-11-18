# Floorp's new tab and home: beacon's services, searching Startpage
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

  # beacon's nginx is the list, so new apps show up on their own
  beacon = inputs.self.nixosConfigurations."beacon-${themeName}".config;
  inherit (beacon.proxy) domain;

  # subdomain -> card; unknown ones still show, under Other
  meta =
  {
    media = { name = "Jellyfin"; desc = "Films and shows"; group = "Media"; icon = "jellyfin.svg"; };
    music = { name = "Navidrome"; desc = "Music"; group = "Media"; icon = "navidrome.svg"; };
    photos = { name = "Immich"; desc = "Photos"; group = "Media"; icon = "immich.svg"; };
    books = { name = "Audiobookshelf"; desc = "Audiobooks, podcasts"; group = "Media"; icon = "audiobookshelf.svg"; };

    notes = { name = "SilverBullet"; desc = "Notes"; group = "Daily"; icon = "silverbullet.png"; };
    tasks = { name = "Vikunja"; desc = "Tasks"; group = "Daily"; icon = "vikunja.svg"; };
    cal = { name = "Radicale"; desc = "Calendar, contacts"; group = "Daily"; icon = "radicale.svg"; };
    rss = { name = "Miniflux"; desc = "Feeds"; group = "Daily"; icon = "miniflux-light.svg"; };
    links = { name = "Linkding"; desc = "Bookmarks"; group = "Daily"; icon = "linkding.svg"; };
    recipes = { name = "Mealie"; desc = "Recipes"; group = "Daily"; icon = "mealie.svg"; };
    budget = { name = "Actual"; desc = "Budget"; group = "Daily"; icon = "actual-budget.svg"; };
    docs = { name = "Paperless"; desc = "Documents"; group = "Daily"; icon = "paperless-ngx.svg"; };

    files = { name = "FileBrowser"; desc = "All of tank"; group = "Tools"; icon = "filebrowser.svg"; };
    sync = { name = "Syncthing"; desc = "Device sync"; group = "Tools"; icon = "syncthing.svg"; };
    search = { name = "SearXNG"; desc = "Metasearch"; group = "Tools"; icon = "searxng.svg"; };
    pdf = { name = "Stirling PDF"; desc = "PDF tools"; group = "Tools"; icon = "stirling-pdf.svg"; };
    draw = { name = "Excalidraw"; desc = "Whiteboard"; group = "Tools"; icon = "excalidraw.svg"; };
    bin = { name = "wastebin"; desc = "Pastes"; group = "Tools"; icon = null; };
    flow = { name = "n8n"; desc = "Automations"; group = "Tools"; icon = "n8n.svg"; };
    watch = { name = "changedetection"; desc = "Page watcher"; group = "Tools"; icon = "changedetection.svg"; };

    git = { name = "Forgejo"; desc = "Git"; group = "Dev"; icon = "forgejo.svg"; };
    vault = { name = "Vaultwarden"; desc = "Passwords"; group = "Dev"; icon = "vaultwarden-light.svg"; };
    sh = { name = "Atuin"; desc = "Shell history"; group = "Dev"; icon = "atuin.svg"; };
    ntfy = { name = "ntfy"; desc = "Notifications"; group = "Dev"; icon = "ntfy.svg"; };

    home = { name = "Glance"; desc = "Dashboard"; group = "System"; icon = "glance.svg"; };
    status = { name = "Gatus"; desc = "Uptime"; group = "System"; icon = "gatus.svg"; };
    metrics = { name = "Beszel"; desc = "Host metrics"; group = "System"; icon = "beszel.svg"; };
    disks = { name = "Scrutiny"; desc = "Disk health"; group = "System"; icon = "scrutiny-light.svg"; };
    id = { name = "Pocket ID"; desc = "Identity"; group = "System"; icon = "pocket-id-light.svg"; };
    auth = { name = "Tinyauth"; desc = "Login gate"; group = "System"; icon = "tinyauth.svg"; };
  };
  groups = [ "Media" "Daily" "Tools" "Dev" "System" "Other" ];

  services = map (host: (meta.${host} or { name = host; desc = ""; group = "Other"; icon = null; }) //
  {
    inherit host;
    url = "https://${host}.${domain}";
    icon = lib.mapNullable (i: "icons/${i}") (meta.${host}.icon or null);
  }) (lib.filter (h: h != "@") (lib.attrNames beacon.proxy.hosts));

  # dashboard-icons at a pinned commit, fetched at build time, not per visit
  rev = "d4b500dc40a8e1043b1581cabb7208892cf35472";
  icons = pkgs.linkFarm "startpage-icons" (lib.mapAttrsToList (file: hash:
  {
    name = file;
    path = pkgs.fetchurl
    {
      url = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons@${rev}/${lib.last (lib.splitString "." file)}/${file}";
      inherit hash;
    };
  }) (lib.importJSON ./icons.json));

  # palette (+ shade, crust) and fonts into @name@
  theme = import ../recolor.nix { inherit lib subst; palette = config.themes.palette; };
  fill = file: pkgs.writeText (baseNameOf file) (subst
  {
    sans = config.stylix.fonts.sansSerif.name;
    mono = config.stylix.fonts.monospace.name;
  } (theme.override file));

  data = pkgs.writeText "services.js" ''
    const GROUPS = ${builtins.toJSON groups};
    const SERVICES = ${builtins.toJSON services};
  '';

  page = pkgs.runCommand "startpage" { } ''
    mkdir $out
    cp ${fill ./index.html} $out/index.html
    cp ${fill ./style.css} $out/style.css
    cp ${./app.js} $out/app.js
    cp ${data} $out/services.js
    ln -s ${icons} $out/icons
  '';
  url = "file://${page}/index.html";
in
{
  programs.floorp.profiles.default.settings =
  {
    "floorp.newtab.overrides.newtaburl" = url;
    "browser.startup.homepage" = url;
  };
}
