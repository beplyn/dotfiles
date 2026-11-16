{
  pkgs,
  username,
  email,
  osConfig,
  headless,
  forgejoHost,
  ...
}:

let
  # pre-commit: unstages new non-image binaries and excludes them
  noBinaries = pkgs.writeShellApplication
  {
    name = "git-no-binaries";
    runtimeInputs = [ pkgs.git pkgs.file pkgs.coreutils pkgs.gnugrep ];
    text = builtins.readFile ./no-binaries.sh;
  };
in
{
  programs.git =
  {
    enable = true;
    # global excludes: binaries by extension, images stay tracked
    ignores =
    [
      # objects and libraries
      "*.o" "*.obj" "*.ko" "*.elf" "*.a" "*.lib" "*.so" "*.so.*" "*.dylib" "*.dll"
      "*.exe" "*.out" "*.app" "*.bin" "*.hex" "*.wasm"
      # bytecode
      "*.pyc" "*.pyo" "*.class" "*.jar" "*.war" "*.beam" "*.luac"
      # archives and packages
      "*.zip" "*.7z" "*.rar" "*.tar" "*.tar.*" "*.tgz" "*.gz" "*.bz2" "*.xz" "*.zst"
      "*.deb" "*.rpm" "*.apk" "*.AppImage" "*.msi" "*.dmg" "*.iso" "*.img"
      # databases
      "*.db" "*.sqlite" "*.sqlite3"
    ];
    settings =
    {
      user =
      {
        name = username;
        inherit email;
      };
      init.defaultBranch = "master";
      pull.rebase = true;
      core.editor = if headless then "vim" else "nvim";
      safe =
      {
        directory = [ "/etc/nixos" ];
      };
      # config hooks run alongside each repo's own .git/hooks
      hook.no-binaries =
      {
        event = "pre-commit";
        command = "${noBinaries}/bin/git-no-binaries";
      };
      url."git@${forgejoHost}:".pushInsteadOf = "https://${forgejoHost}/";
      alias =
      {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
    };
    signing =
    {
      # exact uid, so only this host's key (from `rebuild`) can match
      key = "=${username} (${osConfig.networking.hostName}) <${email}>";
      signByDefault = true;
    };
  };
}
