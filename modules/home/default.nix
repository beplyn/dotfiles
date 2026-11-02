{ lib, headless, ... }:

{
  imports =
  [
    ./dev
    ./cli
    ../theme
  ]
  ++ lib.optional (!headless) ./desktop;
}
