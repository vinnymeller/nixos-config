{
  pkgs,
  ...
}:
{
  services = {
    openssh = {
      enable = true;
      ports = [ 2222 ];
      settings = {
        PermitRootLogin = "no";
        X11Forwarding = false;
        AllowUsers = [
          "vinny"
          "ssh_tunnel"
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

  systemd.user.services."start-ngrok-ssh-tunnel" = {
    enable = true;
    script = ''
      ${pkgs.ngrok}/bin/ngrok tcp 2222 --remote-addr 1.tcp.ngrok.io:27824
    '';
    serviceConfig = {
      Restart = "always";
      RestartSec = "10";
    };
    wantedBy = [ "default.target" ];
  };

}
