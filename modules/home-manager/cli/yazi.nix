{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      opener = {
        edit = [
          {
            run = "nvim \"$@\"";
            block = true;
            for = "unix";
          }
        ];
      };
    };
  };

  xdg.configFile."yazi/theme.toml".text = ''
    [mgr]
    cwd = { fg = "#cba6f7" }
    hovered = { fg = "#11111b", bg = "#cba6f7" }
    preview_hovered = { underline = true }
    find_keyword = { fg = "#f9e2af", italic = true }
    find_position = { fg = "#f38ba8", italic = true }
    marker_copied = { fg = "#a6e3a1", bg = "#a6e3a1" }
    marker_cut = { fg = "#f38ba8", bg = "#f38ba8" }
    marker_marked = { fg = "#f9e2af", bg = "#f9e2af" }
    marker_selected = { fg = "#cba6f7", bg = "#cba6f7" }
    tab_active = { fg = "#11111b", bg = "#cba6f7" }
    tab_inactive = { fg = "#cdd6f4", bg = "#313244" }
    border_style = { fg = "#6c7086" }

    [mode]
    normal_main = { fg = "#11111b", bg = "#cba6f7", bold = true }
    select_main = { fg = "#11111b", bg = "#a6e3a1", bold = true }
    unset_main = { fg = "#11111b", bg = "#f38ba8", bold = true }

    [status]
    overall = { fg = "#cdd6f4", bg = "#313244" }

    [which]
    mask = { bg = "#181825" }
    cand = { fg = "#89b4fa" }
    rest = { fg = "#6c7086" }
    desc = { fg = "#cba6f7" }
    separator = "  "

    [confirm]
    border = { fg = "#cba6f7" }
    title = { fg = "#cba6f7" }
    body = { fg = "#cdd6f4" }
    list = { fg = "#cdd6f4" }
    btn_yes = { fg = "#11111b", bg = "#a6e3a1" }
    btn_no = { fg = "#11111b", bg = "#f38ba8" }
  '';
}
