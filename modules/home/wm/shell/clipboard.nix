{
  lib,
  pkgs,
  ...
}:

{
  # History lives in elephant's clipboard provider (see walker.nix) and is
  # browsed with `walker -m clipboard`, so it shares the launcher's theme.
  # wl-clip-persist keeps a selection alive after its source app closes.
  services.wl-clip-persist =
  {
    enable = true;
    clipboardType = "regular";
  };

  xdg.configFile."elephant/clipboard.toml".source = (pkgs.formats.toml { }).generate "elephant-clipboard"
  {
    max_items = 250;
    ignore_symbols = false;
    pinned_on_top = true;
    image_editor_cmd = "${lib.getExe pkgs.satty} --filename %FILE%";
  };

  home.packages = [ pkgs.wl-clipboard ];
}
