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
)

# text sources
sources=(
  "fortune -s"
  "fortune -s"
  "date +%A"
  "whoami"
  "hostname"
)

# short text only, banners get wide
short_sources=(
  "date +%A"
  "date +%H:%M"
  "whoami"
  "hostname"
  "echo hello"
  "echo moo"
)

figlets=(standard slant small shadow big banner block bubble digital lean doom starwars isometric1 graffiti)
toilets=(future mono9 pagga smblock emboss emboss2 circle bigmono9 smmono9)

speaker()
{
  case $((RANDOM % 4)) in
    0) printf cowsay ;;
    1) printf cowthink ;;
    2) printf 'ponysay' ;;
    3) printf 'ponythink' ;;
  esac
}

roll()
{
  case $((RANDOM % 6)) in
    # a toy on its own
    0 | 1) pick "${solo[@]}" ;;
    # something says something, maybe in rainbow
    2 | 3)
      local cmd
      cmd="$(pick "${sources[@]}") | $(speaker)"
      ((RANDOM % 2)) && cmd+=" | lolcat"
      printf '%s' "$cmd"
      ;;
    # banner text
    4)
      local cmd
      cmd="$(pick "${short_sources[@]}") | figlet -f $(pick "${figlets[@]}")"
      ((RANDOM % 3)) && cmd+=" | lolcat"
      printf '%s' "$cmd"
      ;;
    5)
      local filter
      filter=--metal
      ((RANDOM % 2)) && filter=--gay
      printf '%s | toilet -f %s %s' "$(pick "${short_sources[@]}")" "$(pick "${toilets[@]}")" "$filter"
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
