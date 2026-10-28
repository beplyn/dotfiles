{ lib, pkgs, ... }:

let
  # Map every MIME type in `types` to one desktop entry.
  defaults = app: types: lib.genAttrs types (_: [ app ]);

  images =
  [
    "image/png"
    "image/jpeg"
    "image/gif"
    "image/webp"
    "image/avif"
    "image/heic"
    "image/bmp"
    "image/tiff"
    "image/svg+xml"
    "image/x-icon"
  ];

  videos =
  [
    "video/mp4"
    "video/x-matroska"
    "video/webm"
    "video/quicktime"
    "video/x-msvideo"
    "video/mpeg"
    "video/ogg"
    "audio/mpeg"
    "audio/flac"
    "audio/ogg"
    "audio/opus"
    "audio/wav"
    "audio/x-wav"
    "audio/mp4"
    "audio/aac"
  ];

  documents =
  [
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    "application/msword"
    "application/rtf"
    "application/vnd.oasis.opendocument.text"
  ];

  spreadsheets =
  [
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    "application/vnd.ms-excel"
    "text/csv"
    "application/vnd.oasis.opendocument.spreadsheet"
  ];

  presentations =
  [
    "application/vnd.openxmlformats-officedocument.presentationml.presentation"
    "application/vnd.ms-powerpoint"
    "application/vnd.oasis.opendocument.presentation"
  ];
in
{
  home.packages = [ pkgs.loupe ];

  programs.zathura =
  {
    enable = true;
    options =
    {
      selection-clipboard = "clipboard";
      recolor = false;
    };
  };

  programs.mpv =
  {
    enable = true;
    config =
    {
      hwdec = "auto-safe";
      vo = "gpu-next";
      keep-open = true;
      save-position-on-quit = true;
    };
  };

  # Browser types are claimed by zen (setAsDefaultBrowser in browsers.nix).
  xdg.mimeApps =
  {
    enable = true;
    defaultApplications =
      defaults "org.gnome.Loupe.desktop" images
      // defaults "mpv.desktop" videos
      // defaults "org.pwmt.zathura.desktop" [ "application/pdf" ]
      // defaults "writer.desktop" documents
      // defaults "calc.desktop" spreadsheets
      // defaults "impress.desktop" presentations
      // defaults "org.gnome.Nautilus.desktop" [ "inode/directory" ];
  };
}
