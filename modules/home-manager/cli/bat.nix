{
  home.sessionVariables = {
    PAGER = "bat --paging=always";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
  };
  programs.bat = {
    enable = true;
    config = {
      theme = "Catppuccin Mocha";
      style = "numbers,changes,header";
    };
  };
}
