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
    };
}
