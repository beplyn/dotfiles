{ inputs, ... }:

# shader animations, included from kdl.nix
{
  imports = [ inputs.nirimation.homeManagerModules.default ];

  programs.nirimation =
  {
    enable = true;
    animation = "glitch-cyberpunk";
  };
}
