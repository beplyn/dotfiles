# fun: roll a random terminal toy, alone or as a pipeline like
# `fortune | cowsay | lolcat`. -n prints the roll without running it
pick()
{
  local items=("$@")
  printf "%s" "${items[RANDOM % $#]}"
}

# full-screen ones, run on their own; q or ctrl-c quits
solo=(
  "sl"
  "sl -a"
  "sl -l"
  "sl -F"
  "sl -alF"
  "cmatrix -ab"
  "cmatrix -r"
  "pipes-rs"
  "asciiquarium -t"
  "cbonsai -li"
  "cbonsai -l -L 48"
  "nyancat"
  "genact"
  "lavat -g -c $FUN_ACCENT -k $FUN_ACCENT2 -G"
  "lavat -g -c $FUN_ACCENT -k $FUN_ACCENT2 -b 16 -r 3"
  "tty-clock -cs -C 5"
  "terminal-parrot"
  "globe -s -g 8"
  "globe -s -n -g 8"
  "neo"
  "krabby random"
  "gti --version"
)

# text sources
sources=(
  "fortune -s"
  "fortune -s"
  "date +%A"
)

# short text only, banners get wide
short_sources=(
  "date +%A"
  "date +%H:%M"
  "echo hello"
  "echo moo"
  "echo meow"
  "echo nix btw"
)

figlets=(standard slant small shadow big banner block bubble digital lean doom starwars isometric1 graffiti)
toilets=(future mono9 pagga smblock emboss emboss2 circle bigmono9 smmono9)
boxes=(cat dog parchment scroll peek santa unicornsay tux bear mouse dragon whirly)
cfonts=(block simpleBlock simple 3d simple3d chrome huge shade slick grid pallet tiny)

# lolcat or its faster twin
rainbow()
{
  pick lolcat dotacat
}

speaker()
{
  case $((RANDOM % 5)) in
    0) printf cowsay ;;
    1) printf cowthink ;;
    2) printf 'ponysay' ;;
    3) printf 'ponythink' ;;
    4) printf 'boxes -d %s' "$(pick "${boxes[@]}")" ;;
  esac
}

roll()
{
  case $((RANDOM % 7)) in
    # a toy on its own
    0 | 1) pick "${solo[@]}" ;;
    # something says something, maybe in rainbow; ponies bring their own colours
    2 | 3)
      local cmd who
      who="$(speaker)"
      cmd="$(pick "${sources[@]}") | $who"
      [[ $who != pony* ]] && ((RANDOM % 2)) && cmd+=" | $(rainbow)"
      printf '%s' "$cmd"
      ;;
    # banner text
    4)
      local cmd
      cmd="$(pick "${short_sources[@]}") | figlet -f $(pick "${figlets[@]}")"
      ((RANDOM % 3)) && cmd+=" | $(rainbow)"
      printf '%s' "$cmd"
      ;;
    5)
      local filter
      filter=--metal
      ((RANDOM % 2)) && filter=--gay
      printf '%s | toilet -f %s %s' "$(pick "${short_sources[@]}")" "$(pick "${toilets[@]}")" "$filter"
      ;;
    # cfonts takes the text as an argument, in a scheme gradient
    6)
      # shellcheck disable=SC2016 # the $(...) runs at eval, not here
      printf 'cfonts "$(%s)" -f %s -g "#%s,#%s"' "$(pick "${short_sources[@]}")" "$(pick "${cfonts[@]}")" "$FUN_ACCENT" "$FUN_ACCENT2"
      ;;
  esac
}

dry=0
if [ "${1:-}" = "-n" ]; then
  dry=1
fi

cmd="$(roll)"
printf '\e[2m$ %s\e[0m\n' "$cmd" >&2
if [ "$dry" -eq 0 ]; then
  eval "$cmd"
fi
