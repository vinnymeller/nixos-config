{ ... }: {
    programs.git = {
        enable = true;
        userName = "Vinny Meller";
        userEmail = "vinnymeller@gmail.com";
        extraConfig = {
            push.autoSetupRemote = true;
            push.default = "simple";
            pull.rebase = true;
            core.editor = "nvim";
        };
        aliases = {
            pall = "!f() { git commit -am \"$1\" && git push; }; f";
            cob = "checkout -b";
            del = "branch -D";
            br = "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate";
            lg = "!git log --pretty=format:\"%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) [%an]\" --abbrev-commit -30";
        };

    };
}
