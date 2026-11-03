# Nix only wires stylix (colours, font, opacity) and the shells; the rest is wezterm.lua
{
  programs.wezterm =
  {
    enable = true;
    enableBashIntegration = true;
    extraConfig = builtins.readFile ./wezterm.lua;
  };

  # the integration lands in ~/.bashrc, so HM has to own it
  programs.bash.enable = true;
}
