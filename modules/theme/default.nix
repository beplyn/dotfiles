{ config, lib, themeName, ... }:

let
  palettes = {
    catppuccin = builtins.fromTOML (builtins.readFile ./catppuccin.toml);
    gruvbox = builtins.fromTOML (builtins.readFile ./gruvbox.toml);
    nord = builtins.fromTOML (builtins.readFile ./nord.toml);
  };
in
{
  options.themes = {
    active = lib.mkOption {
      type = lib.types.enum (builtins.attrNames palettes);
      default = themeName;
      description = "The active dark theme.";
    };

    palette = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      description = "Colors from the active theme.";
    };
  };

  config.themes.palette = palettes.${config.themes.active} // {
    text = palettes.${config.themes.active}.foreground;
    muted = palettes.${config.themes.active}.surfaceBright;
    accent = palettes.${config.themes.active}.purple;
    error = palettes.${config.themes.active}.red;
    success = palettes.${config.themes.active}.green;
    warning = palettes.${config.themes.active}.yellow;
  };
}
