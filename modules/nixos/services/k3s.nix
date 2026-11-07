{ config, lib, pkgs, ... }:

# two phases: k3s + Sealed Secrets first, then seal the token against the live controller and enable ddns
let
  cfg = config.k3s;
  manifests = ./k8s;
  sealedToken = manifests + "/cloudflare-api-token.sealed.yaml";
  # the proxy's ACME cert reuses the ddns token
  acmeToken = cfg.ddns.enable && config.proxy.enable && config.proxy.tls == "acme";
in
{
  options.k3s =
  {
    enable = lib.mkEnableOption "a single-node k3s server with the Sealed Secrets controller";
    ddns.enable = lib.mkEnableOption "the Cloudflare DDNS workload, needs the sealed token from phase 2";
  };

  config = lib.mkIf cfg.enable
  {
    assertions =
    [
      {
        assertion = !cfg.ddns.enable || builtins.pathExists sealedToken;
        message = "k3s.ddns.enable needs k8s/cloudflare-api-token.sealed.yaml: seal the token first and git add it";
      }
    ];

    services.k3s =
    {
      enable = true;
      role = "server";
      # kubectl without sudo for wheel, except on gated hosts: cluster-admin is root
      extraFlags =
        lib.optionals (!config.rebuildGate.enable)
        [
          "--write-kubeconfig-mode=0640"
          "--write-kubeconfig-group=wheel"
        ]
      # nginx already owns 80/443
      ++ lib.optionals config.proxy.enable
      [
        "--disable=traefik"
        "--disable=servicelb"
      ];

      # rendered into /var/lib/rancher/k3s/server/manifests, applied by the k3s deploy controller
      manifests =
      {
        sealed-secrets.content =
        {
          apiVersion = "helm.cattle.io/v1";
          kind = "HelmChart";
          metadata =
          {
            name = "sealed-secrets";
            namespace = "kube-system";
          };
          spec =
          {
            repo = "https://bitnami.github.io/sealed-secrets";
            chart = "sealed-secrets";
            targetNamespace = "kube-system";
            # kubeseal's default controller name
            valuesContent = ''
              fullnameOverride: sealed-secrets-controller
            '';
          };
        };

        # phase 1, so the SealedSecret never races its namespace
        ddns-namespace.content =
        {
          apiVersion = "v1";
          kind = "Namespace";
          metadata.name = "ddns";
        };
      }
      // lib.optionalAttrs cfg.ddns.enable
      {
        ddns.source = manifests + "/ddns.yaml";
        ddns-token.source = sealedToken;
      };
    };

    # the k3s updater takes over the proxy's records
    proxy.dyndns = lib.mkIf cfg.ddns.enable false;
    # and ACME uses its sealed token, so rebuild doesn't ask for another
    proxy.acmeEnvFile = lib.mkIf acmeToken "/run/acme-cloudflare/env";

    # the unsealed Secret as an env file, root-only and never on disk
    systemd.services.acme-cloudflare-token = lib.mkIf acmeToken
    {
      wants = [ "k3s.service" ];
      after = [ "k3s.service" ];
      path = [ config.services.k3s.package pkgs.coreutils ];
      serviceConfig =
      {
        Type = "oneshot";
        RemainAfterExit = true;
        RuntimeDirectory = "acme-cloudflare";
        RuntimeDirectoryMode = "0700";
        UMask = "0077";
        TimeoutStartSec = "6min";
      };
      # the controller unseals it a while after k3s starts
      script = ''
        for _ in $(seq 60); do
          token="$(k3s kubectl -n ddns get secret cloudflare-api-token \
            -o jsonpath='{.data.CLOUDFLARE_API_TOKEN}' 2>/dev/null || true)"
          if [ -n "$token" ]; then
            printf 'CF_DNS_API_TOKEN=%s\n' "$(printf '%s' "$token" | base64 -d)" > /run/acme-cloudflare/env
            exit 0
          fi
          sleep 5
        done
        echo "no unsealed cloudflare-api-token in ddns" >&2
        exit 1
      '';
    };
    systemd.services."acme-order-renew-${config.proxy.domain}" = lib.mkIf acmeToken
    {
      requires = [ "acme-cloudflare-token.service" ];
      after = [ "acme-cloudflare-token.service" ];
    };

    environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    # k3s already provides kubectl
    environment.systemPackages = [ pkgs.kubeseal ];

    # pods reach the API server on the host through cni0
    networking.firewall.trustedInterfaces = [ "cni0" ];
  };
}
