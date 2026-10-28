{ inputs, ... }:

# Custom shader animations; the generated KDL is included from kdl.nix.
{
  imports = [ inputs.nirimation.homeManagerModules.default ];

  programs.nirimation =
  {
    enable = true;
    animation = "glitch-cyberpunk";
  };
}
