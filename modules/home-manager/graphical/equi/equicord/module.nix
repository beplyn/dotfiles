{
  ...
}:

{
  imports = [
    ./themes.nix
    ./plugins.nix
  ];
  programs.equibop.equicord.settings = {
    autoUpdate = false;
    autoUpdateNotification = false;
    enableOnlineThemes = true;
    useQuickCss = false;
    transparent = true;
    nativeTitleBar = false;
  };
}
