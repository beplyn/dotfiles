{
  config,
  lib,
  ...
}:

# one wg0 mesh: beacon listens (listenPort), the desktops dial in (endpoint).
# The private key stays root-only in /var/secrets (rebuild asks for it); the
# public keys come from the root-only vars file (scripts/wireguard).
let
  cfg = config.wireguard;
  keyFile = "/var/secrets/wireguard/wg0.key";
in
{
  options.wireguard =
  {
    enable = lib.mkEnableOption "the wg0 WireGuard interface";

    address = lib.mkOption
    {
      type = lib.types.str;
      example = "10.100.0.2/24";
      description = "This host's address on wg0, CIDR.";
    };

    listenPort = lib.mkOption
    {
      type = lib.types.nullOr lib.types.port;
      default = null;
      description = "UDP port to listen on and open in the firewall; null for a dial-out-only client.";
    };

    peers = lib.mkOption
    {
      type = lib.types.listOf (lib.types.submodule
      {
        options =
        {
          publicKey = lib.mkOption
          {
            type = lib.types.str;
            default = "";
            description = "The peer's public key (wg pubkey). Empty peers are left out until it is filled in.";
          };

          allowedIPs = lib.mkOption
          {
            type = lib.types.listOf lib.types.str;
            description = "Addresses routed to this peer (its wg0 address for a single host).";
          };

          endpoint = lib.mkOption
          {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "example.com:51820";
            description = "host:port to dial; only for a peer that listens.";
          };

          persistentKeepalive = lib.mkOption
          {
            type = lib.types.nullOr lib.types.int;
            default = null;
            example = 25;
            description = "Seconds between keepalives, to hold a NAT open from behind.";
          };
        };
      });
      default = [ ];
      description = "The other ends of wg0.";
    };
  };

  config = lib.mkIf cfg.enable
  {
    networking.wireguard.enable = true;

    networking.wireguard.interfaces.wg0 =
    {
      ips = [ cfg.address ];
      listenPort = cfg.listenPort;
      privateKeyFile = keyFile;
      peers = map (p:
      {
        inherit (p) publicKey allowedIPs endpoint persistentKeepalive;
      }) (lib.filter (p: p.publicKey != "") cfg.peers);
    };

    networking.firewall.allowedUDPPorts = lib.optional (cfg.listenPort != null) cfg.listenPort;

    rebuild.secrets.${keyFile}.description = "WireGuard private key for wg0 (wg genkey | tee key | wg pubkey)";
  };
}
