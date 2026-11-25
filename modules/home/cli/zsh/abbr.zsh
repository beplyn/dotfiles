# fish's abbreviations for zsh. `abbr add gs git status` makes gs expand to git status
# when space or enter follows it in command position (the start of the line, or after | ; & or a bracket).
# the nix config's abbrs are always there; `abbr add` keeps yours in $__abbr_file across shells

__abbr_file=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/abbrs

__abbr_expand()
{
  [[ $LBUFFER =~ '(^|[|;&(][[:space:]]*)([^[:space:]|;&()]+)$' ]] || return 0
  local word=$match[2]
  (( ${+__abbrs[$word]} )) || return 0
  LBUFFER=${LBUFFER%$word}${__abbrs[$word]}
}

__abbr_space()
{
  __abbr_expand
  zle self-insert
}

__abbr_enter()
{
  __abbr_expand
  zle .accept-line
}

zle -N __abbr_space
zle -N accept-line __abbr_enter
bindkey ' ' __abbr_space

# one line per abbr: name<TAB>expansion; a later line for the same name wins
__abbr_load()
{
  [[ -f $__abbr_file ]] || return 0
  local name expansion
  while IFS=$'\t' read -r name expansion; do
    [[ -n $name ]] && __abbrs[$name]=$expansion
  done < $__abbr_file
}
__abbr_load

abbr()
{
  local cmd=${1-}
  (( $# )) && shift
  case $cmd in
    ''|list|l)
      local name
      for name in ${(ko)__abbrs}; do
        print -r -- "abbr $name ${(q)__abbrs[$name]}"
      done
      ;;
    add|a)
      if (( $# < 2 )); then
        print -u2 "usage: abbr add NAME EXPANSION..."
        return 1
      fi
      local name=$1 expansion
      shift
      expansion="$*"
      __abbrs[$name]=$expansion
      mkdir -p ${__abbr_file:h}
      local kept
      kept=$(awk -F'\t' -v n="$name" '$1 != n' $__abbr_file 2>/dev/null)
      { [[ -n $kept ]] && print -r -- "$kept"; print -r -- "$name"$'\t'"$expansion"; } > $__abbr_file
      ;;
    erase|e)
      if (( $# != 1 )); then
        print -u2 "usage: abbr erase NAME"
        return 1
      fi
      unset "__abbrs[$1]"
      [[ -f $__abbr_file ]] || return 0
      local kept
      kept=$(awk -F'\t' -v n="$1" '$1 != n' $__abbr_file)
      if [[ -n $kept ]]; then print -r -- "$kept" > $__abbr_file; else : > $__abbr_file; fi
      ;;
    *)
      print -u2 "usage: abbr [list] | add NAME EXPANSION... | erase NAME"
      return 1
      ;;
  esac
}
