{
  config,
  ...
}:

# Stylix puts stylix.icons into the GTK 3/4 settings.ini, but libadwaita apps
# (Nautilus) read the icon theme, like the dark preference Stylix's gnome
# target writes, from GSettings through the portal.
{
  gtk =
  {
    enable = true;
  };

  dconf.settings."org/gnome/desktop/interface".icon-theme = config.gtk.iconTheme.name;
}
