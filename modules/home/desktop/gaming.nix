{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  p = config.themes.palette;
in

{
  config = lib.mkIf osConfig.gaming.enable {
    programs.prismlauncher = {
      enable = true;
      settings = {
        IconTheme = "flat";
        MaxMemAlloc = 18432;
        MenuBarInsteadOfToolBar = false;
      };
      themes.theme = {
        theme = {
          name = "theme";
          widgets = "Fusion";
          colors = {
            AlternateBase = p.surfaceBright;
            Base = p.background;
            BrightText = p.text;
            Button = p.surface;
            ButtonText = p.foreground;
            Highlight = p.accent;
            HighlightedText = p.background;
            Link = p.blue;
            Text = p.foreground;
            ToolTipBase = p.background;
            ToolTipText = p.foreground;
            Window = p.background;
            WindowText = p.text;
            fadeAmount = 0.5;
            fadeColor = p.muted;
          };
        };
      };
    };

    home.activation.prismlauncherUpdateConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      ${lib.getExe pkgs.crudini} --set \
        "${config.xdg.dataHome}/PrismLauncher/prismlauncher_update.cfg" \
        "" auto_check false
    '';
  };
}
