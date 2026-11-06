{ lib, headless, ... }:

{
  imports =
  [
    ./base
    ./services
    ./security
    ../theme
  ]
  # servers: no GUI
  ++ lib.optionals (!headless) [ ./desktop ];
}
