# fish half of wezterm's shell integration: the user vars wezterm.sh sets for bash
status is-interactive; and test "$TERM_PROGRAM" = WezTerm; or return

function __wezterm_set_user_var -a name value
    printf '\e]1337;SetUserVar=%s=%s\a' $name (printf %s $value | base64 | string join '')
end

__wezterm_set_user_var WEZTERM_USER (id -un)
__wezterm_set_user_var WEZTERM_HOST (set -q WEZTERM_HOSTNAME; and echo $WEZTERM_HOSTNAME; or echo $hostname)
__wezterm_set_user_var WEZTERM_IN_TMUX (set -q TMUX; and echo 1; or echo 0)

function __wezterm_preexec --on-event fish_preexec
    __wezterm_set_user_var WEZTERM_PROG $argv[1]
end

function __wezterm_postexec --on-event fish_postexec
    __wezterm_set_user_var WEZTERM_PROG ""
end
