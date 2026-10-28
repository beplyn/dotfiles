{ lib, headless, ... }:

{
  imports = [
    ./base
    ./services
    ../theme
    ../theme/stylix.nix
  ]
  # Servers: no display manager, compositor, fonts or GUI apps.
  ++ lib.optionals (!headless) [ ./desktop ];
}
