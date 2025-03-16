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

  users = {
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

}
