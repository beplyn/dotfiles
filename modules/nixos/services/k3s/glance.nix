{ config, lib, pkgs, subst, themeName, ... }:

let
  dir = "/var/lib/glance";

  # hsl values from docs/themes.md; rose-pine derived from its palette
  themes =
  {
    catppuccin =
    {
      background-color = "240 21 15";
      primary-color = "217 92 83";
      positive-color = "115 54 76";
      negative-color = "347 70 65";
      contrast-multiplier = "1.2";
    };
    gruvbox =
    {
      background-color = "0 0 16";
      primary-color = "43 59 81";
      positive-color = "61 66 44";
      negative-color = "6 96 59";
    };
    rose-pine =
    {
      background-color = "249 22 12";
      primary-color = "189 43 73";
      positive-color = "197 49 38";
      negative-color = "343 76 68";
    };
  };

  # block yaml: glance splices $include text in as-is, so flow style won't parse
  themeFile = pkgs.writeText "glance-theme.yml" ("theme:\n" + lib.concatStrings
    (lib.mapAttrsToList (k: v: "  ${k}: ${v}\n")
    (themes.${themeName} //
    {
      disable-picker = "true";
      custom-css-file = "/assets/user.css";
    })));

  stats = pkgs.writeShellApplication
  {
    name = "glance-rebuild-stats";
    runtimeInputs = with pkgs; [ coreutils jq git gnused ];
    text = subst
    {
      inherit dir themeFile;
      inherit (config.system.nixos) release;
      theme = themeName;
    }
    (builtins.readFile ./glance-rebuild-stats.sh);
  };
in
{
  # runs on every switch/boot and whenever auto-rebuild polls the remote repo
  config = lib.mkIf (builtins.elem "glance" config.k3s.apps)
  {
    system.activationScripts.glanceRebuildStats =
    {
      deps = [ "etc" ];
      text = ''
        ${stats}/bin/glance-rebuild-stats || echo "glance-rebuild-stats failed" >&2
      '';
    };

    systemd.services.glance-rebuild-stats =
    {
      description = "Refresh Glance NixOS rebuild and repo pull stats";
      serviceConfig =
      {
        Type = "oneshot";
        ExecStart = "${stats}/bin/glance-rebuild-stats";
      };
    };

    systemd.paths.glance-rebuild-stats =
    {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathChanged = "/var/lib/auto-rebuild/last-pull";
    };
  };
}
