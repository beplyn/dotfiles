{ config, pkgs, ... }:

let
  p = config.themes.palette;
in

{
  home.packages = with pkgs;
  [
    lazycommit
    lazyjournal
    lazyssh
    onefetch
    serie
  ];
  # k3s TUI; needs KUBECONFIG pointing at a readable kubeconfig
  programs.k9s.enable = true;

  programs.lazygit =
  {
    enable = true;
    settings =
    {
      gui =
      {
        nerdFontsVersion = "3";
        showCommandLog = false;
        theme =
        {
          activeBorderColor =
          [
            p.accent
            "bold"
          ];
          inactiveBorderColor = [ p.muted ];
          searchingActiveBorderColor =
          [
            p.cyan
            "bold"
          ];
          optionsTextColor = [ p.blue ];
          selectedLineBgColor = [ p.surface ];
          inactiveViewSelectedLineBgColor = [ p.surface ];
          cherryPickedCommitBgColor = [ p.accent ];
          cherryPickedCommitFgColor = [ p.background ];
          markedBaseCommitBgColor = [ p.warning ];
          markedBaseCommitFgColor = [ p.background ];
          unstagedChangesColor = [ p.error ];
          defaultFgColor = [ p.foreground ];
        };
      };
      git =
      {
        autoFetch = true;
        autoRefresh = true;
        overrideGpg = true;
      };
    };
  };
}
