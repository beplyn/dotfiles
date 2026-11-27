# Nix wires only stylix (colours, font, opacity) and the shells; wezterm.lua does the rest
{
  programs.wezterm =
  {
    enable = true;
    extraConfig = builtins.readFile ./wezterm.lua;
  };

  # wezterm ships no fish script; fish already emits OSC 7 and 133 itself
  xdg.configFile."fish/conf.d/wezterm.fish".source = ./wezterm.fish;
}
