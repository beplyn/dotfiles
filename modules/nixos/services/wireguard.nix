{
  config,
  lib,
  pkgs,
  ...
}:

# one wg0 mesh: beacon listens (listenPort), the desktops dial in (endpoint).
# The private key stays root-only in /var/secrets (rebuild asks for it); the
# public keys come from the root-only vars file (scripts/wireguard).
let
  cfg = config.wireguard;
  keyFile = "/var/secrets/wireguard/wg0.key";
  # NetworkManager reads the key from an env file, copied into /run at boot
  nmKeyEnv = "/run/wireguard-nm/key.env";
  nmPeers = lib.filter (p: p.publicKey != "") cfg.peers;
in
{
  options.wireguard =
  {
    enable = lib.mkEnableOption "the wg0 WireGuard interface";

    networkManager = lib.mkEnableOption ''
      running wg0 as a NetworkManager profile instead of a systemd interface, so it
      can be toggled from the tray (desktops; the server keeps the systemd one)
    '';

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

  config = lib.mkIf cfg.enable (lib.mkMerge
  [
    {
      networking.firewall.allowedUDPPorts = lib.optional (cfg.listenPort != null) cfg.listenPort;

      rebuild.secrets.${keyFile}.description = "WireGuard private key for wg0 (wg genkey | tee key | wg pubkey)";
    }

    (lib.mkIf (!cfg.networkManager)
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
        }) nmPeers;
      };
    })

    (lib.mkIf cfg.networkManager
    {
      systemd.services.wireguard-nm-key =
      {
        description = "Copy the wg0 private key into an env file for NetworkManager";
        before = [ "NetworkManager.service" "NetworkManager-ensure-profiles.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig =
        {
          Type = "oneshot";
          RemainAfterExit = true;
          RuntimeDirectory = "wireguard-nm";
          RuntimeDirectoryMode = "0700";
          ExecStart = pkgs.writeShellScript "wireguard-nm-key" ''
            printf 'WG_PRIVATE_KEY=%s\n' "$(cat ${keyFile})" > ${nmKeyEnv}
          '';
        };
      };

      # the profile reads the key env file, so its unit must wait for the copy
      systemd.services.NetworkManager-ensure-profiles =
      {
        after = [ "wireguard-nm-key.service" ];
        requires = [ "wireguard-nm-key.service" ];
      };

      networking.networkmanager.ensureProfiles =
      {
        environmentFiles = [ nmKeyEnv ];
        profiles.wg0 =
        {
          connection =
          {
            id = "wg0";
            # fixed, so the profile is the same on every rebuild
            uuid = "6f1c2a9e-3b7d-4e8a-9c21-5d4b8e7f0a13";
            type = "wireguard";
            interface-name = "wg0";
            autoconnect = false;
          };
          wireguard.private-key = "$WG_PRIVATE_KEY";
          ipv4 =
          {
            method = "manual";
            address1 = cfg.address;
          };
          ipv6.method = "disabled";
        }
        # each peer is its own keyfile section, named by its public key
        // lib.listToAttrs (map (p: lib.nameValuePair "wireguard-peer.${p.publicKey}" (
          {
            allowed-ips = lib.concatMapStrings (ip: "${ip};") p.allowedIPs;
          }
          // lib.optionalAttrs (p.endpoint != null) { endpoint = p.endpoint; }
          // lib.optionalAttrs (p.persistentKeepalive != null) { persistent-keepalive = toString p.persistentKeepalive; }
        )) nmPeers);
      };
    })
  ]);
}
