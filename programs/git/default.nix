{...}: {
  programs.git = {
    enable = true;
    userName = "Vinny Meller";
    userEmail = "vinnymeller@proton.me";
    extraConfig = {
      # editor-related
      core.editor = "nv";
      diff.tool = "vimdiff";
      merge.tool = "vimdiff";
      mergetool.vimdiff.path = "nv";
      merge.conflictstyle = "zdiff3";

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
      pall = ''!f() { git commit -am "$1" && git push; }; f'';
      cob = "checkout -b";
      del = "branch -D";
      lg = ''
        !git log --pretty=format:"%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) [%an]" --abbrev-commit -30'';
      clone-bare = ''
        !f() { git clone --bare "$1" "$2" && cd "$2" && git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"; }; f'';
      delete-gone-branches = "!git branch --list --format '%(if:equals=[gone])%(upstream:track)%(then)%(refname:short)%(end)' | sed 's,^refs/heads/,,'  | grep . | xargs git branch -D";
      up = "!git pull && git fetch --prune && git delete-gone-branches && git b";
      ca = "commit --amend";
      cm = "commit -m";
      s = "switch";
      r = "restore";
      b = "for-each-ref --sort=committerdate refs/heads/ --format='%(color:red)%(objectname:short)%(color:reset) %(color:green)%(committerdate:relative)%(color:reset)\t%(HEAD) %(color:yellow)%(refname:short)%(color:reset) %(contents:subject) - %(authorname)'";
      logdr = "!f(){ git log --pretty=format:\"(%h) %ad - %an: %s\" --after=\"$\{1}\" --until=\"$\{2}\"; };f";
    };
    lfs.enable = true;
  };

  programs.gh = {
    enable = true;
    settings = {version = "1";};
  };

  home.shellAliases = {
    fork = "gh repo fork --clone --default-branch-only --remote";
  };
}
