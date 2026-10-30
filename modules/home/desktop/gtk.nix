{
  config,
  ...
}:

# libadwaita reads the icon theme from GSettings, not settings.ini
{
  gtk =
  {
    enable = true;
  };

  dconf.settings."org/gnome/desktop/interface".icon-theme = config.gtk.iconTheme.name;
}
