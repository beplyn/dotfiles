{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    quickemu
    quickgui
    spice-gtk
    virt-viewer
  ];
}
