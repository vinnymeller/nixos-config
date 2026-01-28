{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.mine.git;
in
{
  options.mine.git = {
    enable = mkEnableOption "Enable Git.";
    gpgSignDefault = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to sign commits and tags with GPG by default.
      '';
    };
  };
  config = mkIf cfg.enable {
    programs.git = {
      enable = true;

      settings = {
        user = {
          name = "Vinny Meller";
          email = "vinnymeller@proton.me";
        };
        alias = {
          pall = ''!f() { git commit -am "$1" && git push; }; f'';
          cob = "checkout -b";
          del = "branch -D";
          lg = ''!git log --pretty=format:"%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) [%an]" --abbrev-commit -30'';
          clone-bare = ''!f() { git clone --bare "$1" "$2" && cd "$2" && git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"; }; f'';
          delete-gone-branches = "!git branch --list --format '%(if:equals=[gone])%(upstream:track)%(then)%(refname:short)%(end)' | sed 's,^refs/heads/,,'  | grep . | xargs git branch -D";
          up = "!git pull && git fetch --prune && git delete-gone-branches && git b";
          ca = "commit --amend";
          cm = "commit -m";
          s = "switch";
          r = "restore";
          b = "for-each-ref --sort=committerdate refs/heads/ --format='%(color:red)%(objectname:short)%(color:reset) %(color:green)%(committerdate:relative)%(color:reset)\t%(HEAD) %(color:yellow)%(refname:short)%(color:reset) %(contents:subject) - %(authorname)'";
          logdr = "!f(){ git log --pretty=format:\"(%h) %ad - %an: %s\" --after=\"$\{1}\" --until=\"$\{2}\"; };f";
          graph = "log --graph --all --format='%h %s%n        (%an, %ar)%d' --abbrev-commit";
          swap = "switch @{-1}";
          sw = "switch @{-1}";

        };

        # editor-related
        core.editor = "nv";
        diff.tool = "vimdiff";
        merge.tool = "vimdiff";
        mergetool.vimdiff.path = "nv";
        merge.conflictstyle = "zdiff3";

        # pushing & pulling
        pull.rebase = true;

        push = {
          autoSetupRemote = true;
          default = "simple";
          followTags = true;
        };

        rebase = {
          autoSquash = true;
          autoStash = true;
          updateRefs = true;
        };

        rerere = {
          enabled = true;
          autoUpdate = true;
        };

        # gpg
        commit.gpgSign = cfg.gpgSignDefault;
        tag.gpgSign = cfg.gpgSignDefault;
        user.signingkey = "36CBEC89D5C8540C"; # key that goes with the email above

        # git-spice settings
        spice = {
          submit = {
            navigationComment = false;
          };
          experiment = {
            commitFixup = true;
            commitPick = true;
          };
        };

      };

      lfs.enable = true;
    };

    programs.gh = {
      enable = true;
      settings = {
        version = "1";
      };
      extensions = with pkgs; [
        gh-contribs
        gh-dash
        gh-eco
        gh-f
        gh-notify
        gh-poi
        gh-s
      ];
    };

    home.packages = with pkgs; [
      git-spice
      git-filter-repo
      (mkIf cfg.gpgSignDefault gnupg)
    ];

    home.shellAliases = {
      fork = "gh repo fork --clone --default-branch-only --remote";
      twmg = "twmg() { fork \"$1\" \"$2\"; twm -p \"$2\"; }; twmg";
    };
  };
}
