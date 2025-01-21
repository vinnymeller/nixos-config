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

  systemd.services."ngrok-ssh-tunnel" = {
    enable = true;
    # make it run after the sshd.service is up
    after = [
      "sshd.service"
    ];
    requires = [
      "sshd.service"
    ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10";
      User = "vinny"; # hmm will this work?
      ExecStart = "${pkgs.ngrok}/bin/ngrok tcp 2222 --remote-addr 1.tcp.ngrok.io:27824 --config /home/vinny/.config/ngrok/ngrok.yml";
    };
    wantedBy = [ "multi-user.target" ];
  };

}
