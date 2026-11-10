{
  lib,
  pkgs,
  osConfig,
  ...
}:

# fish stays the login shell; this is for scripts, `nix develop` and whoever runs `bash`
let
  fish = osConfig.programs.fish;

  # y and lg are cd-on-quit functions in .bashrc, an alias would shadow them
  aliases = removeAttrs fish.shellAliases [ "y" "lg" ];

  # linewise: expands only when the abbr is the whole line, like fish's command position
  abbrs = lib.concatStringsSep "\n" (lib.mapAttrsToList
    (k: v: "ble-sabbrev -l ${lib.escapeShellArg "${k}=${if lib.isString v then v else v.expansion}"}")
    fish.shellAbbrs);
in

{
  programs.bash =
  {
    enable = true;

    # fish's ls/grep win over the eza module's aliases
    shellAliases = lib.mapAttrs (_: lib.mkOverride 90) aliases;

    historySize = 100000;
    historyFileSize = 1000000;
    historyControl = [ "erasedups" "ignorespace" ];

    shellOptions =
    [
      "histappend"
      "checkwinsize"
      "extglob"
      "globstar"
      "checkjobs"
      # a bare directory name cds into it, typos in cd get fixed
      "autocd"
      "cdspell"
      "dirspell"
    ];

    # ble.sh wants to be first and attach last
    bashrcExtra = ''
      [[ $- == *i* ]] && source ${pkgs.blesh}/share/blesh/ble.sh --attach=none
    '';

    initExtra = lib.mkMerge
    [
      ''
        if [[ ''${BLE_VERSION-} ]]; then
          source ${./init.bash}
          ${abbrs}
        fi
      ''
      (lib.mkOrder 2000 ''
        [[ ! ''${BLE_VERSION-} ]] || ble-attach
      '')
    ];
  };

  # completions for the commands bash-completion doesn't cover, fish has most of these built in
  programs.carapace =
  {
    enable = true;
    enableBashIntegration = true;
  };
}
