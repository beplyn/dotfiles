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
    transparent = true;
    nativeTitleBar = false;
  };
}
