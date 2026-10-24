{ config, ... }:

let
  p = config.themes.palette;
in

{
  # Themed from our palette below; Stylix's target would set the same keys.
  stylix.targets.bottom.enable = false;

  programs.bottom = {
    enable = true;
    settings = {
      flags = {
        dot_marker = true;
        tree = true;
        battery = true;
        network_use_bytes = true;
      };

      styles = {
        cpu = {
          all_entry_colour = p.accent;
          avg_entry_colour = p.accent;
          cpu_core_colours = [
            p.accent
            p.blue
            p.aqua
            p.purple
          ];
        };

        memory = {
          ram_colour = p.accent;
          cache_colour = p.blue;
          swap_colour = p.aqua;
          arc_colour = p.purple;
        };

        network = {
          rx_colour = p.accent;
          tx_colour = p.blue;
          rx_total_colour = p.aqua;
          tx_total_colour = p.purple;
        };

        battery = {
          high_battery_colour = p.success;
          medium_battery_colour = p.warning;
          low_battery_colour = p.error;
        };

        tables.headers = {
          colour = p.accent;
          bold = true;
        };

        graphs = {
          graph_colour = p.accent;
          legend_text.colour = p.foreground;
        };

        widgets = {
          border_colour = p.muted;
          selected_border_colour = p.accent;
          widget_title = {
            colour = p.accent;
            bold = true;
          };
          text.colour = p.foreground;
          selected_text = {
            colour = p.background;
            bg_colour = p.accent;
          };
          disabled_text.colour = p.muted;
        };
      };
    };
  };
}
