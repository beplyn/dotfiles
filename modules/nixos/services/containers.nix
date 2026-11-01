{ config, lib, ... }:

{
  # not containers.enable, that name is taken
  options.docker.enable = lib.mkEnableOption "the Docker daemon";

  config.virtualisation.docker.enable = config.docker.enable;
}
