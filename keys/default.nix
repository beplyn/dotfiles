# Public keys per host, written here by `rebuild`: keys/<host>/{user.pub,signing.asc,host.pub}
{ lib }:

let
  hosts = lib.attrNames (lib.filterAttrs (_: t: t == "directory") (builtins.readDir ./.));
  # host -> path of keys/<host>/<file>, for the hosts that have it
  collect = file: lib.listToAttrs (lib.concatMap (host:
    lib.optional (builtins.pathExists ./${host}/${file}) (lib.nameValuePair host ./${host}/${file})
  ) hosts);
in
{
  # SSH login keys, trusted on every host running sshd
  userKeys = lib.attrValues (collect "user.pub");
  # sshd host keys, for known_hosts
  hostKeys = collect "host.pub";
}
