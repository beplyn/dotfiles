{ config, lib, pkgs, subst, themeName, themeTable, ... }:

let
  dir = "/var/lib/glance";

  # "H S L" from a base16 hex, the form glance takes
  hsl = hex:
    let
      channel = i: lib.fromHexString (builtins.substring i 2 hex) / 255.0;
      r = channel 0;
      g = channel 2;
      b = channel 4;
      hi = lib.max (lib.max r g) b;
      lo = lib.min (lib.min r g) b;
      d = hi - lo;
      l = (hi + lo) / 2;
      s = if d == 0 then 0 else d / (1 - (if 2 * l - 1 < 0 then 1 - 2 * l else 2 * l - 1));
      hue0 =
        if d == 0 then 0
        else if hi == r then (g - b) / d
        else if hi == g then (b - r) / d + 2
        else (r - g) / d + 4;
      hue = if hue0 < 0 then hue0 + 6 else hue0;
      round = x: toString (builtins.floor (x + 0.5));
    in
    "${round (hue * 60)} ${round (s * 100)} ${round (l * 100)}";

  base = config.lib.stylix.colors;
  glance =
  {
    background-color = hsl base.base00;
    primary-color = hsl base.base0D;
    positive-color = hsl base.base0B;
    negative-color = hsl base.base08;
  }
  // lib.optionalAttrs (themeTable.${themeName} ? contrast)
  {
    contrast-multiplier = themeTable.${themeName}.contrast;
  };

  # block yaml: glance splices $include text in as-is, so flow style won't parse
  themeFile = pkgs.writeText "glance-theme.yml" ("theme:\n" + lib.concatStrings
    (lib.mapAttrsToList (k: v: "  ${k}: ${v}\n")
    (glance //
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
