{ config, ... }:

let
  p = config.themes.palette;
in
{
  programs.tmux =
  {
    enable = true;
    clock24 = true;
    escapeTime = 0;
    historyLimit = 100000;
    keyMode = "vi";
    mouse = true;
    terminal = "tmux-256color";
    prefix = "C-a";
    sensibleOnTop = false;
    extraConfig = ''
      set -g status-style "bg=${p.background},fg=${p.foreground}"
      set -g message-style "bg=${p.surface},fg=${p.foreground}"
      set -g pane-border-style "fg=${p.surfaceBright}"
      set -g pane-active-border-style "fg=${p.accent}"
      set -g status-left "#[fg=${p.background},bg=${p.accent},bold] #S #[fg=${p.accent},bg=${p.background}]"
      set -g status-right "#[fg=${p.muted}]%Y-%m-%d #[fg=${p.accent}]#[fg=${p.background},bg=${p.accent},bold] %H:%M "
      set -g window-status-format "#[fg=${p.muted}] #I:#W "
      set -g window-status-current-format "#[fg=${p.background},bg=${p.accent},bold] #I:#W "
    '';
  };
}
