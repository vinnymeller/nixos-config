{
  options =
    { lib, ... }:
    {
      enableSSHSupport = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      pinentryPackage = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "Pinentry package override. Defaults to pinentry-curses if unset.";
      };
      smartcards = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable GPG smartcard (YubiKey) support.";
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
      programs.ssh.startAgent = lib.mkDefault false;

      services.pcscd.enable = lib.mkDefault true;

      environment.systemPackages = [ pkgs.gnupg ];

      services.udev.packages = lib.mkIf cfg.smartcards [ pkgs.yubikey-personalization ];
      hardware.gpgSmartcards.enable = lib.mkDefault cfg.smartcards;

      programs.gnupg.agent = {
        enable = lib.mkDefault true;
        enableSSHSupport = lib.mkDefault cfg.enableSSHSupport;
        pinentryPackage = if cfg.pinentryPackage != null then cfg.pinentryPackage else pkgs.pinentry-curses;
      };

      environment.shellInit = ''
        gpg-connect-agent /bye
        export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
        export GPG_TTY=$(tty)
      '';

    };

  home =
    {
      cfg,
      lib,
      pkgs,
      ...
    }:
    {
      services.gpg-agent = {
        enable = lib.mkDefault true;
        enableSshSupport = lib.mkDefault cfg.enableSSHSupport;
      };
    };
}
