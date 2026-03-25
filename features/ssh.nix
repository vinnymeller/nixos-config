{
  options =
    { lib, ... }:
    {
      withTunnelUser = lib.mkEnableOption "Create a user for SSH tunneling only";
      allowUsers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Users allowed to SSH in. Defaults to the feature's resolved users list.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 2222;
      };
      githubOverPort443 = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Route github.com SSH through port 443 (ssh.github.com).";
      };
    };

  nixos =
    {
      cfg,
      config,
      lib,
      pkgs,
      ...
    }:
    {
      services.openssh = {
        enable = lib.mkDefault true;
        ports = [ cfg.port ];
        settings = {
          PermitRootLogin = lib.mkDefault "no";
          X11Forwarding = lib.mkDefault false;
          AllowUsers =
            (if cfg.allowUsers != [ ] then cfg.allowUsers else cfg.users)
            ++ lib.optionals cfg.withTunnelUser [ "ssh_tunnel" ];
          PasswordAuthentication = lib.mkDefault false;
          LogLevel = lib.mkDefault "VERBOSE";
        };
        authorizedKeysInHomedir = lib.mkDefault true;
      };

      services.fail2ban.enable = lib.mkDefault true;

      users = lib.mkIf cfg.withTunnelUser {
        users.ssh_tunnel = {
          isNormalUser = true;
          initialHashedPassword = "$6$GUm.78.XWDWW/7CE$TVA9j1bmmKEMiQ2289etaddvpaYpVUUWagW7A.TM6K13RThGq.E3f7MgPh.bBurysjJDDkceZDz7.CEhXUsY6.";
          group = "ssh_tunnel";
          shell = "${pkgs.shadow}/bin/nologin";
        };
        groups.ssh_tunnel = { };
      };
    };

  home =
    { cfg, lib, ... }:
    {
      programs.ssh = {
        enable = lib.mkDefault true;
        enableDefaultConfig = lib.mkDefault false;
        matchBlocks = lib.mkIf cfg.githubOverPort443 {
          "github.com" = {
            hostname = "ssh.github.com";
            port = 443;
            user = "git";
          };
        };
      };
    };
}
