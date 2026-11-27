#compdef rebuild
# rebuild [--host HOST] [THEME]: hosts after --host, themes as the argument
_arguments \
  '(-H --host)'{-H,--host}'[host to switch to]:host:(@hosts@)' \
  '(-h --help)'{-h,--help}'[usage]' \
  '1:theme:(@themes@)'
