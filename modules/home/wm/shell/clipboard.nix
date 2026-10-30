{
  lib,
  pkgs,
  ...
}:

{
  # history via elephant (walker -m clipboard); wl-clip-persist keeps it alive
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
