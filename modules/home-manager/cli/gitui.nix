{ config, ... }:

let
  p = config.themes.palette;
in

{
  # Themed from our palette below; Stylix's target would also write theme.ron.
  stylix.targets.gitui.enable = false;

  programs.gitui = {
    enable = true;
    # Empty patch: keep gitui's default keys (an empty file would log a parse error).
    keyConfig = "()";
    theme = ''
      (
        selection_fg: Some("${p.background}"),
        selection_bg: Some("${p.accent}"),
        cmd_fg: Some("${p.foreground}"),
        cmd_bg: Some("${p.background}"),
        diff_fg: Some("${p.foreground}"),
        diff_add: Some("${p.success}"),
        diff_remove: Some("${p.error}"),
        diff_context: Some("${p.muted}"),
        commit_fg: Some("${p.foreground}"),
        commit_bg: Some("${p.background}"),
        branch_fg: Some("${p.accent}"),
        branch_bg: Some("${p.surface}"),
        tag_fg: Some("${p.warning}"),
        tag_bg: Some("${p.surface}"),
        line_number_fg: Some("${p.muted}"),
        line_number_bg: Some("${p.background}"),
        title_fg: Some("${p.accent}"),
        title_bg: Some("${p.background}"),
        hint_fg: Some("${p.blue}"),
        hint_bg: Some("${p.background}"),
        active_border_fg: Some("${p.accent}"),
        inactive_border_fg: Some("${p.surfaceBright}"),
        searching_border_fg: Some("${p.aqua}"),
        scrollbar_fg: Some("${p.muted}"),
        scrollbar_bg: Some("${p.surface}"),
      )
    '';
  };
}
