{ lib, headless, ... }:

{
  imports =
  [
    ./base
    ./services
    ../theme
  ]
  # servers: no GUI
  ++ lib.optionals (!headless) [ ./desktop ];
}
