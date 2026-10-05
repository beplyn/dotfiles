{ pkgs, ... }:

{
  home.packages = [
    pkgs.btop
  ];

  xdg.configFile."btop/btop.conf".text = ''
    # Catppuccin Mocha with Mauve accents
    color_theme = "catppuccin_mocha.theme"
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

  xdg.configFile."btop/themes/catppuccin_mocha.theme".text = ''
    theme[main_bg]=""
    theme[main_fg]="#cdd6f4"
    theme[title]="#cba6f7"
    theme[hi_fg]="#cba6f7"
    theme[selected_bg]="#45475a"
    theme[selected_fg]="#cba6f7"
    theme[inactive_fg]="#6c7086"
    theme[graph_text]="#cdd6f4"
    theme[meter_bg]="#313244"
    theme[proc_misc]="#f5e0dc"
    theme[cpu_box]="#cba6f7"
    theme[mem_box]="#89b4fa"
    theme[net_box]="#94e2d5"
    theme[proc_box]="#f5c2e7"
    theme[div_line]="#6c7086"
    theme[temp_start]="#a6e3a1"
    theme[temp_mid]="#f9e2af"
    theme[temp_end]="#f38ba8"
    theme[cpu_start]="#94e2d5"
    theme[cpu_mid]="#74c7ec"
    theme[cpu_end]="#b4befe"
    theme[free_start]="#cba6f7"
    theme[free_mid]="#b4befe"
    theme[free_end]="#89b4fa"
    theme[cached_start]="#74c7ec"
    theme[cached_mid]="#89b4fa"
    theme[cached_end]="#b4befe"
    theme[available_start]="#fab387"
    theme[available_mid]="#eba0ac"
    theme[available_end]="#f38ba8"
    theme[used_start]="#a6e3a1"
    theme[used_mid]="#94e2d5"
    theme[used_end]="#89dceb"
    theme[download_start]="#fab387"
    theme[download_mid]="#eba0ac"
    theme[download_end]="#f38ba8"
    theme[upload_start]="#a6e3a1"
    theme[upload_mid]="#94e2d5"
    theme[upload_end]="#89dceb"
    theme[process_start]="#89b4fa"
    theme[process_mid]="#b4befe"
    theme[process_end]="#cba6f7"
  '';
}
