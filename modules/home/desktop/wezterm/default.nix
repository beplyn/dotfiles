# Nix only wires stylix (colours, font, opacity); the rest is wezterm.lua
{
  programs.wezterm =
  {
    enable = true;
    extraConfig = builtins.readFile ./wezterm.lua;
  };
}
