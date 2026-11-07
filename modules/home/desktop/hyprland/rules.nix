{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "opacity 0.75 0.75, class:^(equibop)$"
      "opacity 0.75 0.75, class:^(steam)$"
      "float, class:^(com.gabm.satty)$"
      "float, class:^(steam)$, title:^(notificationtoasts_[0-9]+_desktop)$"
      "no_initial_focus, class:^(steam)$, title:^(notificationtoasts_[0-9]+_desktop)$"
    ];
  };
}
