{
  assertions =
    { features, ... }:
    [
      {
        assertion = features.gpg.enableSSHSupport -> features.ssh.enable;
        message = "features.gpg.enableSSHSupport requires features.ssh to be enabled.";
      }
    ];

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
      # YubiKey smartcard plumbing lives in features/yubikey.nix now. For
      # GPG-on-YubiKey, enable both features.gpg and features.yubikey.
    };

  nixos =
    {
      cfg,
      lib,
      pkgs,
      ...
    }:
    {
      programs.ssh.startAgent = lib.mkDefault false;

      environment.systemPackages = [ pkgs.gnupg ];

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
      ...
    }:
    {
      services.gpg-agent = {
        enable = lib.mkDefault true;
        enableSshSupport = lib.mkDefault cfg.enableSSHSupport;
      };
    };
}
