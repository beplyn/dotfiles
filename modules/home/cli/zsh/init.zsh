# fish's interactive bits for zsh: completion, keys and the fish-style PATH
# (aliases, history and the suggestion and highlight plugins are in default.nix)

# completion: case-insensitive, a menu with descriptions and groups, not a column dump
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*'
zstyle ':completion:*' completer _complete _approximate
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{244}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}no matches%f'

# alt-s: toggles sudo -> sudo -E -> nothing, an empty line takes the last command
__prepend_sudo()
{
  local cmd=$BUFFER
  if [[ -z $cmd ]]; then
    cmd=$(fc -ln -1)
    cmd=${cmd#"${cmd%%[![:space:]]*}"}
  fi
  [[ -z $cmd ]] && return 0
  if [[ $cmd == "sudo -E "* ]]; then
    cmd=${cmd#sudo -E }
  elif [[ $cmd == "sudo "* ]]; then
    cmd="sudo -E ${cmd#sudo }"
  else
    cmd="sudo -E $cmd"
  fi
  BUFFER=$cmd
  CURSOR=${#cmd}
}
zle -N __prepend_sudo
bindkey '^[s' __prepend_sudo

# ctrl-f: cycles $(fzf) -> directories -> nothing at the end of the line
__append_fzf()
{
  local cmd=$BUFFER
  [[ -z $cmd ]] && return 0
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
  BUFFER=$cmd
  CURSOR=${#cmd}
}
zle -N __append_fzf
bindkey '^F' __append_fzf

# `f` (pay-respects) and zoxide are wired by NixOS's /etc/zshrc, not here

# the same as fish_add_path --prepend --move; -U keeps the first copy, so these lead
typeset -U path
path=($HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin $path)

export GPG_TTY=$(tty)
# alt and esc combos fire at once instead of after zsh's 400ms wait
export KEYTIMEOUT=10
