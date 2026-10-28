{ config, ... }:

{
  home.sessionVariables =
  {
    PAGER = "bat --paging=always";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
  };
  home.file.".config/fish/conf.d/home-manager-session-vars.fish".text = ''
    set -gx PAGER ${builtins.toJSON config.home.sessionVariables.PAGER}
    set -gx MANPAGER ${builtins.toJSON config.home.sessionVariables.MANPAGER}
  '';
  programs.bat =
  {
    enable = true;
    config =
    {
      style = "numbers,changes,header";
    };
  };
}
