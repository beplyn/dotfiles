{ config, lib, osConfig, pkgs, ... }:

let
  enabled = lib.toLower osConfig.networking.hostName != "larptop";
in

{
  config = lib.mkIf enabled {
    programs.prismlauncher = {
      enable = true;
      settings = {
        ApplicationTheme = "Catppuccin-Mocha-Mauve";
        IconTheme = "flat";
        MaxMemAlloc = 18432;
        MenuBarInsteadOfToolBar = false;
      };
      themes."Catppuccin-Mocha-Mauve" = {
        theme = {
          name = "Catppuccin Mocha Mauve";
          widgets = "Fusion";
          colors = {
            AlternateBase = "#1e1e2e";
            Base = "#181825";
            BrightText = "#bac2de";
            Button = "#313244";
            ButtonText = "#cdd6f4";
            Highlight = "#cba6f7";
            HighlightedText = "#1e1e2e";
            Link = "#b4befe";
            Text = "#cdd6f4";
            ToolTipBase = "#11111b";
            ToolTipText = "#cdd6f4";
            Window = "#1e1e2e";
            WindowText = "#bac2de";
            fadeAmount = 0.5;
            fadeColor = "#6c7086";
          };
        };
      };
    };

    home.activation.prismlauncherUpdateConfig =
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        ${lib.getExe pkgs.crudini} --set \
          "$HOME/${config.xdg.dataHome}/PrismLauncher/prismlauncher_update.cfg" \
          "" auto_check false
      '';
  };
}
