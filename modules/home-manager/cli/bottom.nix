{ pkgs, ... }:

{
  home.packages = [
    pkgs.bottom
  ];

  xdg.configFile."bottom/bottom.toml".text = ''
    [flags]
    dot_marker = true
    tree = true
    battery = true
    network_use_bytes = true

    [styles.cpu]
    all_entry_colour = "#cba6f7"
    avg_entry_colour = "#cba6f7"
    cpu_core_colours = ["#cba6f7", "#b4befe", "#89b4fa", "#74c7ec"]

    [styles.memory]
    ram_colour = "#cba6f7"
    cache_colour = "#b4befe"
    swap_colour = "#89b4fa"
    arc_colour = "#74c7ec"

    [styles.network]
    rx_colour = "#cba6f7"
    tx_colour = "#b4befe"
    rx_total_colour = "#89b4fa"
    tx_total_colour = "#74c7ec"

    [styles.battery]
    high_battery_colour = "#a6e3a1"
    medium_battery_colour = "#f9e2af"
    low_battery_colour = "#f38ba8"

    [styles.tables]
    headers = { colour = "#cba6f7", bold = true }

    [styles.graphs]
    graph_colour = "#cba6f7"
    legend_text = { colour = "#cdd6f4" }

    [styles.widgets]
    border_colour = "#6c7086"
    selected_border_colour = "#cba6f7"
    widget_title = { colour = "#cba6f7", bold = true }
    text = { colour = "#cdd6f4" }
    selected_text = { colour = "#11111b", bg_colour = "#cba6f7" }
    disabled_text = { colour = "#6c7086" }
  '';
}
