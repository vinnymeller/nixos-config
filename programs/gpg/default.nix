# REFERENCES:
# https://web.archive.org/web/20230904085342/https://rzetterberg.github.io/yubikey-gpg-nixos.html
{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.ssh.startAgent = false;

  services.pcscd.enable = true;

  environment.systemPackages = with pkgs; [ gnupg ];

  services.udev.packages = with pkgs; [ yubikey-personalization ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  environment.shellInit = ''
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';

  systemd.user.timers."restart-gpg-agent" = {
    enable = true;
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/5";
      Unit = "restart-gpg-agent.service";
    };
  };

  systemd.user.services."restart-gpg-agent" = {
    enable = true;
    script = ''
      ${pkgs.gnupg}/bin/gpgconf --kill gpg-agent
    '';
    serviceConfig = {
      Type = "oneshot";
    };
  };
}
