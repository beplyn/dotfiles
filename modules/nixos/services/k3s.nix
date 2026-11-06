{ config, lib, pkgs, ... }:

# two phases: k3s + Sealed Secrets first, then seal the token against the live controller and enable ddns
let
  cfg = config.k3s;
  manifests = ./k8s;
  sealedToken = manifests + "/cloudflare-api-token.sealed.yaml";
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
      # kubectl without sudo for wheel
      extraFlags =
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

    environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
    # k3s already provides kubectl
    environment.systemPackages = [ pkgs.kubeseal ];

    # pods reach the API server on the host through cni0
    networking.firewall.trustedInterfaces = [ "cni0" ];
  };
}
