{
  config,
  lib,
  email,
  ...
}:

# nginx behind Cloudflare, no tunnel; secrets stay in /var/secrets, out of the store
let
  cfg = config.proxy;
  secrets = "/var/secrets";
  # nginx isn't root; systemd copies root-only files here
  creds = "/run/credentials/nginx.service";

  # https://www.cloudflare.com/ips/
  cloudflareIPs =
  [
    "173.245.48.0/20"
    "103.21.244.0/22"
    "103.22.200.0/22"
    "103.31.4.0/22"
    "141.101.64.0/18"
    "108.162.192.0/18"
    "190.93.240.0/20"
    "188.114.96.0/20"
    "197.234.240.0/22"
    "198.41.128.0/17"
    "162.158.0.0/15"
    "104.16.0.0/13"
    "104.24.0.0/14"
    "172.64.0.0/13"
    "131.0.72.0/22"
    "2400:cb00::/32"
    "2606:4700::/32"
    "2803:f800::/32"
    "2405:b500::/32"
    "2405:8100::/32"
    "2a06:98c0::/29"
    "2c0f:f248::/32"
  ];

  # "@" is the apex
  fqdn = name: if name == "@" then cfg.domain else "${name}.${cfg.domain}";

  tls =
    if cfg.tls == "acme" then
      { useACMEHost = cfg.domain; }
    else
      {
        sslCertificate = "${creds}/cert.pem";
        sslCertificateKey = "${creds}/key.pem";
      };

  vhost = name: host:
  {
    name = fqdn name;
    value = tls //
    {
      forceSSL = true;
      # Host, X-Real-IP, X-Forwarded-* via recommendedProxySettings
      locations."/" =
      {
        proxyPass = "http://${host.address}:${toString host.port}";
        # Upgrade + Connection
        proxyWebsockets = host.websockets;
      };
      extraConfig = ''
        # skipped Cloudflare and isn't on the LAN
        if ($allowed_peer = 0) { return 444; }
      ''
      + lib.optionalString (host.maxBodySize != null) ''
        client_max_body_size ${host.maxBodySize};
      ''
      + lib.optionalString cfg.originPulls ''
        ssl_client_certificate ${creds}/origin-pull-ca.pem;
        ssl_verify_client on;
      '';
    };
  };
in
{
  options.proxy =
  {
    enable = lib.mkEnableOption "Nginx behind Cloudflare's proxy, with Cloudflare dynamic DNS";

    domain = lib.mkOption
    {
      type = lib.types.str;
      example = "example.com";
      description = "Cloudflare zone the services live under.";
    };

    tls = lib.mkOption
    {
      type = lib.types.enum [ "acme" "origin" ];
      default = "acme";
      description = ''
        Origin certificate for Cloudflare's Full (Strict) mode.
        acme: Let's Encrypt wildcard via DNS-01, token in ${secrets}/acme-cloudflare.env.
        origin: Cloudflare Origin CA at ${secrets}/certs/{cert,key}.pem.
      '';
    };

    originPulls = lib.mkOption
    {
      type = lib.types.bool;
      default = false;
      description = ''
        Require Cloudflare's Authenticated Origin Pulls client certificate,
        CA at ${secrets}/certs/origin-pull-ca.pem.
      '';
    };

    dyndns = lib.mkOption
    {
      type = lib.types.bool;
      default = true;
      description = "Keep the records pointed here with cloudflare-dyndns; off when something else does it.";
    };

    acmeEnvFile = lib.mkOption
    {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/run/acme-cloudflare/env";
      description = ''
        Env file with CF_DNS_API_TOKEN provided by something else.
        null: rebuild asks for it at ''${secrets}/acme-cloudflare.env.
      '';
    };

    lanSubnets = lib.mkOption
    {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "192.168.2.0/24" ];
      description = ''
        Local networks let in directly, for split-horizon DNS: no Cloudflare upload cap or
        hairpin NAT, same certificate. They're never taken as Cloudflare, so CF-Connecting-IP
        from them is ignored.
      '';
    };

    ipv6 = lib.mkOption
    {
      type = lib.types.bool;
      default = false;
      description = "Also keep AAAA records updated.";
    };

    hosts = lib.mkOption
    {
      type = lib.types.attrsOf (lib.types.submodule
      {
        options =
        {
          port = lib.mkOption
          {
            type = lib.types.port;
            description = "Upstream port.";
          };
          address = lib.mkOption
          {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Upstream address.";
          };
          websockets = lib.mkOption
          {
            type = lib.types.bool;
            default = true;
            description = "Pass WebSocket upgrades through.";
          };
          maxBodySize = lib.mkOption
          {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "100m";
            description = "Largest request body (uploads); null keeps nginx's 1m.";
          };
        };
      });
      default = { };
      example = { git.port = 3000; };
      description = "Subdomains (\"@\" for the apex) to reverse proxy, each to a local upstream.";
    };
  };

  config = lib.mkIf cfg.enable
  {
    assertions =
    [
      {
        assertion = !(cfg.originPulls && cfg.lanSubnets != [ ]);
        message = "proxy.originPulls rejects LAN clients, which have no Cloudflare client certificate";
      }
    ];

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    # rebuild asks for whichever are missing
    rebuild.secrets =
      lib.optionalAttrs cfg.dyndns
      {
        "${secrets}/cloudflare-ddns.token" =
        {
          description = "Cloudflare API token (Zone.DNS edit) for dyndns";
          restart = [ "cloudflare-dyndns.service" ];
        };
      }
    // lib.optionalAttrs (cfg.tls == "acme" && cfg.acmeEnvFile == null)
    {
      "${secrets}/acme-cloudflare.env" =
      {
        description = "Cloudflare API token (Zone.DNS edit) for ACME DNS-01";
        prefix = "CF_DNS_API_TOKEN=";
        restart = [ "acme-order-renew-${cfg.domain}.service" ];
      };
    }
    // lib.optionalAttrs (cfg.tls == "origin")
    {
      "${secrets}/certs/cert.pem" =
      {
        description = "Cloudflare Origin CA certificate";
        file = true;
        restart = [ "nginx.service" ];
      };
      "${secrets}/certs/key.pem" =
      {
        description = "Cloudflare Origin CA private key";
        file = true;
        restart = [ "nginx.service" ];
      };
    }
    // lib.optionalAttrs cfg.originPulls
    {
      "${secrets}/certs/origin-pull-ca.pem" =
      {
        description = "Cloudflare Authenticated Origin Pulls CA";
        file = true;
        restart = [ "nginx.service" ];
      };
    };

    services.cloudflare-dyndns =
    {
      enable = cfg.dyndns;
      apiTokenFile = "${secrets}/cloudflare-ddns.token";
      domains = if cfg.hosts == { } then [ cfg.domain ] else map fqdn (lib.attrNames cfg.hosts);
      proxied = true;
      inherit (cfg) ipv6;
    };

    security.acme = lib.mkIf (cfg.tls == "acme")
    {
      acceptTerms = true;
      defaults.email = email;
      certs.${cfg.domain} =
      {
        extraDomainNames = [ "*.${cfg.domain}" ];
        dnsProvider = "cloudflare";
        # the LAN resolver caches the missing TXT record past lego's timeout
        dnsResolver = "1.1.1.1:53";
        # CF_DNS_API_TOKEN=...
        environmentFile = if cfg.acmeEnvFile == null then "${secrets}/acme-cloudflare.env" else cfg.acmeEnvFile;
        group = config.services.nginx.group;
      };
    };

    systemd.services.nginx.serviceConfig.LoadCredential =
      lib.optionals (cfg.tls == "origin")
      [
        "cert.pem:${secrets}/certs/cert.pem"
        "key.pem:${secrets}/certs/key.pem"
      ]
      ++ lib.optional cfg.originPulls "origin-pull-ca.pem:${secrets}/certs/origin-pull-ca.pem";

    services.nginx =
    {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      # real client IP; $allowed_peer checks the actual peer
      commonHttpConfig = ''
        ${lib.concatMapStrings (ip: "set_real_ip_from ${ip};\n") cloudflareIPs}
        real_ip_header CF-Connecting-IP;

        geo $realip_remote_addr $allowed_peer
        {
          default 0;
        ${lib.concatMapStrings (ip: "  ${ip} 1;\n") (cloudflareIPs ++ cfg.lanSubnets)}
        }
      '';

      virtualHosts =
      {
        # bare IP / unknown Host: drop, no cert handed out
        "_" =
        {
          default = true;
          rejectSSL = true;
          locations."/".return = "444";
        };
      }
      // lib.mapAttrs' vhost cfg.hosts;
    };
  };
}
