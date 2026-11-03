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

  # wezterm ships no fish script; fish already emits OSC 7 and 133 itself
  xdg.configFile."fish/conf.d/wezterm.fish".source = ./wezterm.fish;
}
