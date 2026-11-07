{ ... }:

# second session next to niri; config lives in home-manager (desktop/sway)
{
  programs.sway =
  {
    enable = true;
    wrapperFeatures.gtk = true;
    # foot, swaylock and co.: wezterm, hyprlock and hypridle instead
    extraPackages = [ ];
  };
}
