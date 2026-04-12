{
  options =
    { lib, config, ... }:
    {
      userName = lib.mkOption {
        type = lib.types.str;
        default = "Vinny Meller";
      };
      userEmail = lib.mkOption {
        type = lib.types.str;
        default = "vinnymeller@proton.me";
      };
      gpgSign = lib.mkOption {
        type = lib.types.bool;
        default = config.features.gpg.enable;
        description = "Whether to sign commits and tags with GPG by default.";
      };
      signingKey = lib.mkOption {
        type = lib.types.str;
        default = "36CBEC89D5C8540C";
      };
      editor = lib.mkOption {
        type = lib.types.str;
        default = "nv";
      };
    };

  assertions =
    { features, ... }:
    [
      {
        assertion = features.git.gpgSign -> features.gpg.enable;
        message = "features.git.gpgSign requires features.gpg.enable to be true.";
      }
    ];

  home =
    {
      cfg,
      lib,
      pkgs,
      ...
    }:
    {
      programs.git = {
        enable = lib.mkDefault true;

        settings = {
          user = {
            name = lib.mkDefault cfg.userName;
            email = lib.mkDefault cfg.userEmail;
            signingkey = lib.mkDefault cfg.signingKey;
          };
          alias = {
            pall = lib.mkDefault ''!f() { git commit -am "$1" && git push; }; f'';
            cob = lib.mkDefault "checkout -b";
            del = lib.mkDefault "branch -D";
            lg = lib.mkDefault ''!git log --pretty=format:"%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) [%an]" --abbrev-commit -30'';
            clone-bare = lib.mkDefault ''!f() { git clone --bare "$1" "$2" && cd "$2" && git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"; }; f'';
            delete-gone-branches = lib.mkDefault "!git branch --list --format '%(if:equals=[gone])%(upstream:track)%(then)%(refname:short)%(end)' | sed 's,^refs/heads/,,'  | grep . | xargs git branch -D";
            up = lib.mkDefault "!git pull && git fetch --prune && git delete-gone-branches && git b";
            ca = lib.mkDefault "commit --amend";
            cm = lib.mkDefault "commit -m";
            s = lib.mkDefault "switch";
            r = lib.mkDefault "restore";
            b = lib.mkDefault "for-each-ref --sort=committerdate refs/heads/ --format='%(color:red)%(objectname:short)%(color:reset) %(color:green)%(committerdate:relative)%(color:reset)\t%(HEAD) %(color:yellow)%(refname:short)%(color:reset) %(contents:subject) - %(authorname)'";
            logdr = lib.mkDefault "!f(){ git log --pretty=format:\"(%h) %ad - %an: %s\" --after=\"\${1}\" --until=\"\${2}\"; };f";
            graph = lib.mkDefault "log --graph --all --format='%h %s%n        (%an, %ar)%d' --abbrev-commit";
            swap = lib.mkDefault "switch @{-1}";
            sw = lib.mkDefault "switch @{-1}";
          };

          core.editor = lib.mkDefault cfg.editor;
          diff.tool = lib.mkDefault "vimdiff";
          merge.tool = lib.mkDefault "vimdiff";
          mergetool.vimdiff.path = lib.mkDefault cfg.editor;
          merge.conflictstyle = lib.mkDefault "zdiff3";

          pull.rebase = lib.mkDefault true;

          push = {
            autoSetupRemote = lib.mkDefault true;
            default = lib.mkDefault "simple";
            followTags = lib.mkDefault true;
          };

          rebase = {
            autoSquash = lib.mkDefault true;
            autoStash = lib.mkDefault true;
            updateRefs = lib.mkDefault true;
          };

          rerere = {
            enabled = lib.mkDefault true;
            autoUpdate = lib.mkDefault true;
          };

          commit.gpgSign = lib.mkDefault cfg.gpgSign;
          tag.gpgSign = lib.mkDefault cfg.gpgSign;

          spice = {
            submit.navigationComment = lib.mkDefault false;
            experiment = {
              commitFixup = lib.mkDefault true;
              commitPick = lib.mkDefault true;
            };
          };
        };

        lfs.enable = lib.mkDefault true;
      };

      programs.gh = {
        enable = lib.mkDefault true;
        settings.version = lib.mkDefault "1";
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

      home.packages =
        with pkgs;
        [
          git-spice
          git-filter-repo
        ]
        ++ lib.optionals cfg.gpgSign [ gnupg ];

      home.shellAliases = {
        fork = lib.mkDefault "gh repo fork --clone --default-branch-only --remote";
        twmg = lib.mkDefault ''twmg() { fork "$1" "$2"; twm -p "$2"; }; twmg'';
      };
    };
}
