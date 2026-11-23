{
  imports =
  [
    ./themes
    ./plugins.nix
  ];
  programs.equibop.equicord.settings =
  {
    autoUpdate = false;
    autoUpdateNotification = false;
    enableOnlineThemes = true;
    useQuickCss = true;
    transparent = false;
    nativeTitleBar = false;
  };
}
