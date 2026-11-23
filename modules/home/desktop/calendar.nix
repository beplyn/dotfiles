# the dashboard's calendar: one vdir of .ics files, read and written by
# haku-calendar.py (icalendar, recurring-ical-events)
{
  config,
  lib,
  pkgs,
  ...
}:

let
  dir = "${config.xdg.dataHome}/calendars/local";

  calendar = pkgs.writers.writePython3Bin "haku-calendar"
  {
    libraries = with pkgs.python3Packages; [
      icalendar
      python-dateutil
      recurring-ical-events
    ];
    flakeIgnore = [ "E501" ];
  }
    (builtins.readFile ./haku-calendar.py);
in
{
  home.packages = [ calendar ];

  # the folder exists before the first run, so the dashboard can watch it
  home.activation.calendar = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${dir}"
  '';

  lib.haku.calendar =
  {
    bin = lib.getExe calendar;
    db = dir;
  };
}
