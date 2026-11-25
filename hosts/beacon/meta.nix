# host metadata, read by lib/mkHost.nix and install.sh (docs/layout.md)
{
  # no display: no GUI, no Steam overlay
  headless = true;
  # asks for lan.* in vars and needs them (network.nix)
  staticLan = true;
}
