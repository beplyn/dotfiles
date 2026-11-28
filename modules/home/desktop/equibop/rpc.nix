{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.nixcord.equibop.settings =
  {
    arRPC = true;
    arRPCDisabled = false;
    arRPCProcessScanning = true;
    arRPCWebSocketAutoReconnect = true;
  };

  # arRPC's database has no linux CS2 binary, so detection never matches it
  home.activation.arrpcCs2 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD env PATH=${lib.makeBinPath [ pkgs.bash pkgs.jq pkgs.coreutils ]} \
      bash ${./patch-detectables.sh} "$HOME/.config/equibop/sessionData/arrpc-detectable-db.json"
  '';
}
