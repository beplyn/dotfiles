# rebuild [--host HOST] [THEME]: no files, themes as the argument, hosts after --host
complete -c rebuild -f
complete -c rebuild -s H -l host -x -a '@hosts@' -d 'host to switch to'
complete -c rebuild -a '@themes@' -d 'theme'
