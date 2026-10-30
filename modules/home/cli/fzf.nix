let
  fd = "fd --hidden --follow --exclude .git";
in
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
    defaultCommand = "${fd} --type f";
    fileWidget =
    {
      command = "${fd} --type f";
      options =
      [
        "--preview 'bat --color=always --style=numbers {}'"
        "--bind 'ctrl-/:toggle-preview'"
      ];
    };
    changeDirWidget =
    {
      command = "${fd} --type d";
      options =
      [
        "--preview 'eza --tree --icons --color=always --level=2 {}'"
      ];
    };
  };
}
