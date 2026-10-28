{
  programs.fzf =
  {
    enable = true;
    enableFishIntegration = true;
    defaultOptions =
    [
      "--height=40%"
      "--layout=reverse"
      "--border=sharp"
      "--info=inline"
      "--cycle"
      "--multi"
      "--color=dark"
    ];
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidget =
    {
      command = "fd --type f --hidden --follow --exclude .git";
      options =
      [
        "--preview 'bat --color=always --style=numbers {}'"
        "--bind 'ctrl-/:toggle-preview'"
      ];
    };
    changeDirWidget =
    {
      command = "fd --type d --hidden --follow --exclude .git";
      options =
      [
        "--preview 'tree -C {}'"
      ];
    };
  };
}
