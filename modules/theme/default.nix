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

  config.themes.palette = palettes.${config.themes.active};
}
