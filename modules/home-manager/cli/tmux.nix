{
  programs.tmux = {
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
      set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
      set -g message-style "bg=#313244,fg=#cdd6f4"
      set -g pane-border-style "fg=#45475a"
      set -g pane-active-border-style "fg=#cba6f7"
      set -g status-left "#[fg=#11111b,bg=#cba6f7,bold] #S #[fg=#cba6f7,bg=#1e1e2e]"
      set -g status-right "#[fg=#6c7086]%Y-%m-%d #[fg=#cba6f7]#[fg=#11111b,bg=#cba6f7,bold] %H:%M "
      set -g window-status-format "#[fg=#6c7086] #I:#W "
      set -g window-status-current-format "#[fg=#11111b,bg=#cba6f7,bold] #I:#W "
    '';
  };
}
