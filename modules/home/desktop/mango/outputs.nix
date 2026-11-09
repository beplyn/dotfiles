{
  config,
  lib,
  osConfig,
  ...
}:

# host monitors -> mango monitor rules, left to right
let
  place = acc: m:
  {
    x = acc.x + m.width;
    rules = acc.rules ++
    [
      "monitor_rule=name:^${m.name}$,width:${toString m.width},height:${toString m.height},refresh:${toString m.refresh},x:${toString acc.x},y:0"
    ];
  };
  primary = lib.findFirst (m: m.primary) null osConfig.monitors;
  mmsg = lib.getExe' osConfig.programs.mango.package "mmsg";
in
{
  xdg.configFile."mango/outputs.conf".source = config.lib.haku.mangoConf "outputs" (
    lib.concatLines (
      (lib.foldl' place { x = 0; rules = [ ]; } osConfig.monitors).rules
      ++ lib.optional (primary != null) "exec_once=${mmsg} dispatch focusmon,${primary.name}"
    )
  );
}
