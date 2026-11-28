{
  imports =
  [
    ./themes
    ./plugins.nix
    ./quickcss.nix
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
