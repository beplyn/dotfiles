# ble.sh gives bash what fish has out of the box:
# autosuggestions, syntax highlighting, a completion menu and abbreviations

# history every session sees, like fish
bleopt history_share=1
# a menu with descriptions instead of a column dump
bleopt complete_menu_style=desc
# no "[ble: EOF]" or exit-status lines between prompts, starship handles that
bleopt prompt_eol_mark=''
bleopt exec_errexit_mark=''
bleopt exec_elapsed_mark=''

# up/down: search history for what is already typed, plain history when empty
ble-bind -m emacs -f up 'history-substring-search-backward hide-status:point=end:empty=history-move'
ble-bind -m emacs -f down 'history-substring-search-forward hide-status:point=end:empty=history-move'

# ctrl-f/right take the whole suggestion, alt-right one word of it (ble defaults);
# end only moves the cursor, and alt-f is the fzf bind below
blehook/eval-after-load complete '
  ble-bind -m auto_complete -f end -
  ble-bind -m auto_complete -f M-f -
'

# fish's alt-s: toggles sudo -> sudo -E -> nothing, an empty line takes the last command
__prepend_sudo()
{
  local cmd=$READLINE_LINE
  if [[ -z $cmd ]]; then
    cmd=$(fc -ln -1)
    cmd=${cmd#"${cmd%%[![:space:]]*}"}
  fi
  [[ -z $cmd ]] && return
  if [[ $cmd == "sudo -E "* ]]; then
    cmd=${cmd#sudo -E }
  elif [[ $cmd == "sudo "* ]]; then
    cmd="sudo -E ${cmd#sudo }"
  else
    cmd="sudo -E $cmd"
  fi
  READLINE_LINE=$cmd
  READLINE_POINT=${#cmd}
}
ble-bind -m emacs -x M-s __prepend_sudo

# fish's alt-f: cycles $(fzf) -> directories -> nothing at the end of the line
__append_fzf()
{
  local cmd=$READLINE_LINE
  [[ -z $cmd ]] && return
  local files='$(fzf)' dirs='$(fd -t directory | fzf)'
  if [[ $cmd == *" $files" ]]; then
    cmd="${cmd%"$files"}$dirs"
  elif [[ $cmd == *" $dirs" ]]; then
    cmd=${cmd%" $dirs"}
  elif [[ $cmd == *" " ]]; then
    cmd+=$files
  else
    cmd+=" $files"
  fi
  READLINE_LINE=$cmd
  READLINE_POINT=${#cmd}
}
ble-bind -m emacs -x M-f __append_fzf
