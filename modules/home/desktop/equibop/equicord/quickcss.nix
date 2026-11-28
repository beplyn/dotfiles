{ config, lib, pkgs, ... }:

let
  css = pkgs.writeText "equibop-quickcss.css" config.equibop.quickCss;
  dest = lib.escapeShellArg "${config.xdg.configHome}/equibop/settings/quickCss.css";
in
{
  options.equibop.quickCss = lib.mkOption
  {
    type = lib.types.lines;
    default = "";
    description = "Quick CSS for Equibop, written in place so it reloads live.";
  };

  config.home.activation.equibopQuickCss = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run mkdir -p "$(dirname ${dest})"
    # a store symlink would stay pointed at the old file, so replace it
    if [ -L ${dest} ]; then
      run rm ${dest}
    fi
    if [ -e ${dest} ]; then
      run chmod u+w ${dest}
    fi
    # same inode each rebuild, so Equibop sees a change event
    run cp --no-preserve=mode ${css} ${dest}
  '';
}
