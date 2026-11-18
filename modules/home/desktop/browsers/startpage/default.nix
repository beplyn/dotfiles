# Floorp's new tab and home: a TUI launcher for beacon's services
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

  # pane order = the 1-9 keys
  categories = [ "MEDIA" "DAILY" "TOOLS" "DEV" "INFRA" "OTHER" ];

  # subdomain -> row; unknown ones land in OTHER
  meta =
  {
    media = { name = "Jellyfin"; category = "MEDIA"; icon = "film"; tags = [ "movies" "shows" "video" ]; };
    music = { name = "Navidrome"; category = "MEDIA"; icon = "music"; tags = [ "subsonic" ]; };
    photos = { name = "Immich"; category = "MEDIA"; icon = "image"; tags = [ "pictures" "gallery" ]; };
    books = { name = "Audiobookshelf"; category = "MEDIA"; icon = "headphones"; tags = [ "audiobooks" "podcasts" ]; };

    notes = { name = "SilverBullet"; category = "DAILY"; icon = "notebook"; tags = [ "markdown" "wiki" ]; };
    tasks = { name = "Vikunja"; category = "DAILY"; icon = "check"; tags = [ "todo" ]; };
    cal = { name = "Radicale"; category = "DAILY"; icon = "calendar"; tags = [ "caldav" "carddav" "contacts" ]; };
    rss = { name = "Miniflux"; category = "DAILY"; icon = "rss"; tags = [ "feeds" "news" ]; };
    links = { name = "Linkding"; category = "DAILY"; icon = "bookmark"; tags = [ "bookmarks" ]; };
    recipes = { name = "Mealie"; category = "DAILY"; icon = "utensils"; tags = [ "food" "cooking" ]; };
    budget = { name = "Actual"; category = "DAILY"; icon = "card"; tags = [ "money" "finance" ]; };
    docs = { name = "Paperless"; category = "DAILY"; icon = "file"; tags = [ "documents" "scans" ]; };

    files = { name = "FileBrowser"; category = "TOOLS"; icon = "folder"; tags = [ "tank" "share" ]; };
    sync = { name = "Syncthing"; category = "TOOLS"; icon = "sync"; tags = [ "devices" ]; };
    search = { name = "SearXNG"; category = "TOOLS"; icon = "search"; tags = [ "metasearch" ]; };
    pdf = { name = "Stirling PDF"; category = "TOOLS"; icon = "filetext"; tags = [ "merge" "convert" ]; };
    draw = { name = "Excalidraw"; category = "TOOLS"; icon = "shapes"; tags = [ "whiteboard" "diagram" ]; };
    bin = { name = "wastebin"; category = "TOOLS"; icon = "clipboard"; tags = [ "paste" ]; };
    flow = { name = "n8n"; category = "TOOLS"; icon = "workflow"; tags = [ "automation" "webhooks" ]; };
    watch = { name = "changedetection"; category = "TOOLS"; icon = "eye"; tags = [ "monitor" "diff" ]; };

    git = { name = "Forgejo"; category = "DEV"; icon = "git"; tags = [ "repos" "code" ]; };
    vault = { name = "Vaultwarden"; category = "DEV"; icon = "lock"; tags = [ "passwords" "bitwarden" ]; };
    sh = { name = "Atuin"; category = "DEV"; icon = "terminal"; tags = [ "shell" "history" ]; };
    ntfy = { name = "ntfy"; category = "DEV"; icon = "bell"; tags = [ "notifications" "push" ]; };

    home = { name = "Glance"; category = "INFRA"; icon = "grid"; tags = [ "dashboard" ]; };
    status = { name = "Gatus"; category = "INFRA"; icon = "activity"; tags = [ "uptime" "health" ]; };
    metrics = { name = "Beszel"; category = "INFRA"; icon = "chart"; tags = [ "cpu" "memory" ]; };
    disks = { name = "Scrutiny"; category = "INFRA"; icon = "disk"; tags = [ "smart" "drives" ]; };
    id = { name = "Pocket ID"; category = "INFRA"; icon = "idcard"; tags = [ "oidc" "sso" ]; };
    auth = { name = "Tinyauth"; category = "INFRA"; icon = "shield"; tags = [ "login" "forward" ]; };
  };

  rows = map (host: (meta.${host} or { name = host; category = "OTHER"; icon = "globe"; tags = [ ]; }) //
  {
    inherit host;
    url = "https://${host}.${domain}";
  }) (lib.filter (h: h != "@") (lib.attrNames beacon.proxy.hosts));

  # [{ category, services }] in pane order, empty panes dropped
  services = lib.filter (c: c.services != [ ]) (map (category:
  {
    inherit category;
    services = lib.sortOn (s: lib.toLower s.name) (lib.filter (s: s.category == category) rows);
  }) categories);

  # Stylix's scheme as --base00..--base0F
  c = config.lib.stylix.colors.withHashtag;
  stylixCss = pkgs.writeText "stylix.css" ''
    :root
    {
    ${lib.concatMapStrings (i: "  --base0${i}: ${c."base0${i}"};\n")
      [ "0" "1" "2" "3" "4" "5" "6" "7" "8" "9" "A" "B" "C" "D" "E" "F" ]}}
  '';

  app = pkgs.writeText "app.js" (subst { services = builtins.toJSON services; } (builtins.readFile ./app.js));
  fonts = "${pkgs.maple-mono.woff2}/share/fonts/woff2";

  page = pkgs.runCommand "startpage" { } ''
    mkdir -p $out/fonts
    cp ${./index.html} $out/index.html
    cp ${./style.css} $out/style.css
    cp ${stylixCss} $out/stylix.css
    cp ${app} $out/app.js
    for f in Regular Italic Bold; do
      cp ${fonts}/MapleMono-$f.ttf.woff2 $out/fonts/MapleMono-$f.woff2
    done
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
