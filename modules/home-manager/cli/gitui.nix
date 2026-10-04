{ pkgs, ... }:

{
  home.packages = [
    pkgs.gitui
  ];

  xdg.configFile."gitui/theme.ron".text = ''
    (
      selection_fg: Some("#11111b"),
      selection_bg: Some("#cba6f7"),
      cmd_fg: Some("#cdd6f4"),
      cmd_bg: Some("#1e1e2e"),
      diff_fg: Some("#cdd6f4"),
      diff_add: Some("#a6e3a1"),
      diff_remove: Some("#f38ba8"),
      diff_context: Some("#6c7086"),
      commit_fg: Some("#cdd6f4"),
      commit_bg: Some("#1e1e2e"),
      branch_fg: Some("#cba6f7"),
      branch_bg: Some("#313244"),
      tag_fg: Some("#f9e2af"),
      tag_bg: Some("#313244"),
      line_number_fg: Some("#6c7086"),
      line_number_bg: Some("#1e1e2e"),
      title_fg: Some("#cba6f7"),
      title_bg: Some("#1e1e2e"),
      hint_fg: Some("#89b4fa"),
      hint_bg: Some("#1e1e2e"),
      active_border_fg: Some("#cba6f7"),
      inactive_border_fg: Some("#45475a"),
      searching_border_fg: Some("#89dceb"),
      scrollbar_fg: Some("#6c7086"),
      scrollbar_bg: Some("#313244"),
    )
  '';
}
