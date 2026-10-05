{ pkgs, ... }:

{
  home.packages = with pkgs; [
    lazycommit
    lazyjournal
    lazyssh
    serie
  ];
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        nerdFontsVersion = "3";
        showCommandLog = false;
        theme = {
          activeBorderColor = [
            "#cba6f7"
            "bold"
          ];
          inactiveBorderColor = [ "#6c7086" ];
          searchingActiveBorderColor = [
            "#89dceb"
            "bold"
          ];
          optionsTextColor = [ "#89b4fa" ];
          selectedLineBgColor = [ "#313244" ];
          inactiveViewSelectedLineBgColor = [ "#313244" ];
          cherryPickedCommitBgColor = [ "#cba6f7" ];
          cherryPickedCommitFgColor = [ "#11111b" ];
          markedBaseCommitBgColor = [ "#f9e2af" ];
          markedBaseCommitFgColor = [ "#11111b" ];
          unstagedChangesColor = [ "#f38ba8" ];
          defaultFgColor = [ "#cdd6f4" ];
        };
      };
      git = {
        autoFetch = true;
        autoRefresh = true;
      };
    };
  };
}
