{ lib, lan, ... }:

# its address, gateway and subnet are vars (vars/README.md), not in the repo
let
  inherit (lan) address subnet gateway;
  prefix = lib.last (lib.splitString "/" subnet);
in
{
  assertions =
  [
    {
      assertion = address != "" && gateway != "" && lib.hasInfix "/" subnet;
      message = "beacon needs lan.address, lan.gateway and lan.subnet (CIDR): fill them in with sudoedit /var/secrets/dotfiles/vars.toml";
    }
  ];

  # static ip; no interface-name so it binds to whichever wired NIC is present
  networking.networkmanager.ensureProfiles.profiles.wired =
  {
    connection =
    {
      id = "wired";
      type = "ethernet";
      autoconnect-priority = 100;
    };
    ipv4 =
    {
      method = "manual";
      address1 = "${address}/${prefix},${gateway}";
      dns = "${gateway};";
    };
    ipv6.method = "auto";
  };
}
