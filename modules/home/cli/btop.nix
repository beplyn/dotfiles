{ config, pkgs, ... }:

let
  p = config.themes.palette;
in
{
  home.packages =
  [
    pkgs.btop
  ];

  xdg.configFile."btop/btop.conf".text = ''
    color_theme = "theme.theme"
    theme_background = False
    truecolor = True
    rounded_corners = True
    vim_keys = True
    graph_symbol = "braille"

    shown_boxes = "cpu mem net proc"
    update_ms = 2000
    cpu_bottom = False
    mem_below_net = False

    check_temp = True
    show_coretemp = True
    temp_scale = "celsius"
    cpu_single_graph = True
    show_uptime = True
    base_10_sizes = False
    clock_format = "%X"

    proc_sorting = "cpu lazy"
    proc_tree = True
    proc_reversed = False
    proc_per_core = True
    proc_mem_bytes = True
  '';

  xdg.configFile."btop/themes/theme.theme".text = ''
    theme[main_bg]=""
    theme[main_fg]="${p.foreground}"
    theme[title]="${p.accent}"
    theme[hi_fg]="${p.accent}"
    theme[selected_bg]="${p.surfaceBright}"
    theme[selected_fg]="${p.accent}"
    theme[inactive_fg]="${p.muted}"
    theme[graph_text]="${p.foreground}"
    theme[meter_bg]="${p.surface}"
    theme[proc_misc]="${p.purple}"
    theme[cpu_box]="${p.accent}"
    theme[mem_box]="${p.blue}"
    theme[net_box]="${p.aqua}"
    theme[proc_box]="${p.purple}"
    theme[div_line]="${p.muted}"
    theme[temp_start]="${p.success}"
    theme[temp_mid]="${p.warning}"
    theme[temp_end]="${p.error}"
    theme[cpu_start]="${p.aqua}"
    theme[cpu_mid]="${p.blue}"
    theme[cpu_end]="${p.purple}"
    theme[free_start]="${p.accent}"
    theme[free_mid]="${p.purple}"
    theme[free_end]="${p.blue}"
    theme[cached_start]="${p.blue}"
    theme[cached_mid]="${p.blue}"
    theme[cached_end]="${p.purple}"
    theme[available_start]="${p.orange}"
    theme[available_mid]="${p.red}"
    theme[available_end]="${p.error}"
    theme[used_start]="${p.success}"
    theme[used_mid]="${p.aqua}"
    theme[used_end]="${p.aqua}"
    theme[download_start]="${p.orange}"
    theme[download_mid]="${p.red}"
    theme[download_end]="${p.error}"
    theme[upload_start]="${p.success}"
    theme[upload_mid]="${p.aqua}"
    theme[upload_end]="${p.aqua}"
    theme[process_start]="${p.blue}"
    theme[process_mid]="${p.purple}"
    theme[process_end]="${p.accent}"
  '';
}
