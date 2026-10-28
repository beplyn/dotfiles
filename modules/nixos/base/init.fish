function __prepend_sudo
  set -l cmd (commandline)
  if test -z "$cmd"
    set cmd $history[1]
  end
  if test -z "$cmd"
    return
  end
  if string match -q "sudo -E *" "$cmd"
    commandline -r (string sub -s 9 "$cmd")
  else if string match -q "sudo *" "$cmd"
    commandline -r (string replace -r '^sudo ' 'sudo -E ' "$cmd")
  else
    commandline -r "sudo -E $cmd"
  end
end
bind \es __prepend_sudo

function __append_fzf
  set -l cmd (commandline)
  if test -z "$cmd"
    return
  end
  if string match -q "*q (fzf)" "$cmd"
    commandline -r (string replace -r ' \(fzf\)$' "$cmd")
  else if string match -q "* " "$cmd"
    commandline -r "$cmd(fzf)"
  else
    commandline -r "$cmd (fzf)"
  end
end
bind \ef __append_fzf

fish_add_path --prepend --move \
  $HOME/.nix-profile/bin \
  /nix/var/nix/profiles/default/bin

set -g fish_greeting ""
fastfetch
