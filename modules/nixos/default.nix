{ lib, headless, ... }:

{
  imports = [
    ./base
    ./services
    ../theme
  ]
  # Servers: no display manager, compositor, fonts or GUI apps.
  ++ lib.optionals (!headless) [ ./desktop ];
}
