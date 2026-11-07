{ lib, ... }:

{
  # off: no fj, and rebuild doesn't ask for a token
  options.forgejo.enable = lib.mkOption
  {
    type = lib.types.bool;
    default = true;
    description = "The forgejo CLI (fj) and its token.";
  };
}
