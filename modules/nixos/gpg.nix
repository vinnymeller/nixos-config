{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption;
  cfg = config.mine.gpg;
in
{

  options.mine.gpg = {
    enable = mkEnableOption "Enable gpg";
    autoRestartAgent = mkOption {
      type = lib.types.bool;
      default = true;
      description = "Automatically restart gpg-agent every 5 minutes";
    };
  };

  config = mkIf cfg.enable {

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
      export GPG_TTY=$(tty)
    '';

    systemd.user.timers."restart-gpg-agent" = mkIf cfg.autoRestartAgent{
      enable = true;
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/5";
        Unit = "restart-gpg-agent.service";
      };
    };

    systemd.user.services."restart-gpg-agent" = mkIf cfg.autoRestartAgent {
      enable = true;
      script = ''
        ${pkgs.gnupg}/bin/gpgconf --kill gpg-agent
      '';
      serviceConfig = {
        Type = "oneshot";
      };
    };

  };
}
