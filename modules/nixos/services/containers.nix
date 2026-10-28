{ config, lib, ... }:

{
  # Not `containers.enable`: `containers.<name>` is NixOS's declarative
  # container option.
  options.docker.enable = lib.mkEnableOption "the Docker daemon";

  config.virtualisation.docker.enable = lib.mkIf config.docker.enable true;
}
