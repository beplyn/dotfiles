{ lib, headless, ... }:

{
  imports = [
    ./dev
    ./cli
    ../theme
  ]
  ++ lib.optionals (!headless) [
    ./desktop
    ./wm
  ];
}
