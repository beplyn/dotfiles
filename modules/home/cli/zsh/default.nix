{
  lib,
  pkgs,
  config,
  osConfig,
  subst,
  ...
}:

# fish's aliases, abbrs, keys and greeting, in zsh syntax
let
  fish = osConfig.programs.fish;

  # y and lg must stay functions: they cd on quit, an alias would shadow them
  aliases = removeAttrs fish.shellAliases [ "y" "lg" ];

  # one associative array for init.zsh: key value key value ...
  abbrs = lib.concatStringsSep " " (lib.mapAttrsToList
    (k: v: "${lib.escapeShellArg k} ${lib.escapeShellArg (if lib.isString v then v else v.expansion)}")
    fish.shellAbbrs);

  # the greeting's colours and limits, as in the NixOS greeting
  greeting = lib.mapAttrs (_: lib.removePrefix "#") config.themes.palette //
  {
    chance = "4";
    bannerChance = "10";
    cfonts = lib.getExe pkgs.cfonts;
    diskWarn = "85"; # percent
  };
in

{
  programs.zsh =
  {
    enable = true;
    enableCompletion = true;

    # fish's grey suggestion, accepted with right or ctrl-f
    autosuggestion =
    {
      enable = true;
      highlight = "fg=244";
    };
    syntaxHighlighting.enable = true;

    # up/down: search history for what is already typed, plain history when empty
    historySubstringSearch.enable = true;

    history =
    {
      size = 100000;
      save = 1000000;
      # history every session sees, no duplicates, lines with a leading space stay out
      share = true;
      ignoreAllDups = true;
      ignoreSpace = true;
    };

    setOptions =
    [
      # a bare directory name cds into it, typos in commands get fixed
      "AUTO_CD"
      "CORRECT"
      "CHECK_JOBS"
      "EXTENDED_GLOB"
      "NO_BEEP"
    ];

    # fish's ls/grep win over the eza module's aliases
    shellAliases = lib.mapAttrs (_: lib.mkOverride 90) aliases;

    initContent = lib.mkMerge
    [
      ''
        typeset -gA __abbrs=( ${abbrs} )
      ''
      (builtins.readFile ./abbr.zsh)
      (builtins.readFile ./init.zsh)
      (lib.mkAfter (subst greeting (builtins.readFile ./greeting.zsh)))
    ];
  };

  # completions zsh's own system doesn't cover; fish has most built in
  programs.carapace =
  {
    enable = true;
    enableZshIntegration = true;
  };
}
