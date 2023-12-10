{ ... }: {
  programs.git = {
    enable = true;
    userName = "Vinny Meller";
    userEmail = "vinnymeller@proton.me";
    extraConfig = {

      # editor-related
      core.editor = "nvim";
      diff.tool = "vimdiff";
      merge.tool = "vimdiff";
      mergetool.vimdiff.path = "nvim";
      merge.conflictstyle = "diff3";

      # pushing & pulling
      pull.rebase = true;
      push.autoSetupRemote = true;
      push.default = "simple";
      rebase.autosquash = true;

      # gpg
      commit.gpgSign = true;
      # push.gpgSign = true;  # none of the hosted git providers support this!
      tag.gpgSign = true;
      user.signingkey = "36CBEC89D5C8540C"; # key that goes with the email above
    };

    aliases = {
      pall = "!f() { git commit -am \"$1\" && git push; }; f";
      cob = "checkout -b";
      del = "branch -D";
      br = "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate";
      lg = "!git log --pretty=format:\"%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) [%an]\" --abbrev-commit -30";
      clone-bare = "!f() { git clone --bare \"$1\" \"$2\" && cd \"$2\" && git config remote.origin.fetch \"+refs/heads/*:refs/remotes/origin/*\"; }; f";
    };

  };

  programs.gh = {
    enable = true;
  };

  home.shellAliases = {
    fork = "gh repo fork --clone --default-branch-only --remote";
  };

}
