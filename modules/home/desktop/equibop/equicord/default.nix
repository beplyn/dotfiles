{
  imports =
  [
    ./themes
    ./plugins.nix
  ];
  programs.nixcord.equibopConfig =
  {
    autoUpdate = false;
    autoUpdateNotification = false;
    enableOnlineThemes = true;
    useQuickCss = true;
    transparent = false;
    nativeTitleBar = false;
  };
}
