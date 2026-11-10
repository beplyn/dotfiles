{
  pkgs,
  ...
}:

let
  # cliphist for the quickshell clipboard panel (Mod+V), see clipboard.sh
  clipboard = pkgs.writeShellApplication
  {
    name = "clipboard";
    runtimeInputs = with pkgs;
    [
      cliphist
      wl-clipboard
      coreutils
    ];
    text = builtins.readFile ./clipboard.sh;
  };
in
{
  # history: every wl-copy, text and images; wl-clip-persist keeps a copy
  # alive after the app that made it closes
  services.cliphist =
  {
    enable = true;
    allowImages = true;
    extraOptions =
    [
      "-max-items"
      "250"
    ];
  };

  services.wl-clip-persist =
  {
    enable = true;
    clipboardType = "regular";
  };

  home.packages =
  [
    pkgs.wl-clipboard
    clipboard
  ];

  lib.haku.clipboard = clipboard;
}
