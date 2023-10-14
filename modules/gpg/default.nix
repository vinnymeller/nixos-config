# REFERENCES:
# https://web.archive.org/web/20230904085342/https://rzetterberg.github.io/yubikey-gpg-nixos.html

{ config, lib, pkgs, ... }: {
  programs.ssh.startAgent = false;

  services.pcscd.enable = true;

  environment.systemPackages = with pkgs; [
    gnupg
  ];

  services.udev.packages = with pkgs; [
    yubikey-personalization
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  environment.shellInit = ''
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';
}
