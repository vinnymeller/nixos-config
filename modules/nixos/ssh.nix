{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.ssh;
in
{

  options.mine.ssh = {
    enable = mkEnableOption "Enable ssh";
    withTunnelUser = mkEnableOption "Create user for ssh tunneling only";
  };

  config = mkIf cfg.enable {

    services = {
      openssh = {
        enable = true;
        ports = [ 2222 ];
        settings = {
          PermitRootLogin = "no";
          X11Forwarding = false;
          AllowUsers = [
            "vinny"
            (mkIf cfg.withTunnelUser "ssh_tunnel")
          ];
          PasswordAuthentication = false;
          LogLevel = "VERBOSE";
        };
        authorizedKeysInHomedir = true;
      };
      fail2ban = {
        enable = true;
      };
    };

    users = mkIf cfg.withTunnelUser {
      users = {
        ssh_tunnel = {
          isNormalUser = true;
          initialPassword = "passwordington";
          group = "ssh_tunnel";
          shell = "${pkgs.shadow}/bin/nologin";
        };
      };
      groups = {
        ssh_tunnel = { };
      };
    };

  };
}
