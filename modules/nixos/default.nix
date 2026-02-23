{
  config,
  lib,
  vlib,
  ...
}:
let
  modules = vlib.readModuleFiles ./.;
  inherit (lib) mkEnableOption mkDefault;
  cfg = config.profile;
in
{
  imports = modules;

  options = {
    profile = {
      selfhost = mkEnableOption "Enable self-hosted configuration.";
    };
  };

  config = {
    mine = {
      gpg.enable = mkDefault true;
      ssh.enable = mkDefault true;
      services = {
        github-runners.enable = mkDefault cfg.selfhost;
        immich.enable = mkDefault cfg.selfhost;
        offsiteSync = {
          enable = mkDefault cfg.selfhost;
          rclone.secretFile = ../../secrets/vinnix/rclone.conf.age;
          providers = {
            gdrive = {
              remote = "gdrive-crypt";
              extraArgs = [ "--drive-chunk-size=256M" ];
            };
            storj.remote = "storj-crypt";
            onedrive.remote = "onedrive-crypt";
          };
          onFailure = {
            enable = true;
            notifyUser = "vinny";
          };
        };
        rsvpub.enable = mkDefault cfg.selfhost;
        vtt.enable = mkDefault true;
      };
      networking.enable = mkDefault true;
      nix.enable = mkDefault true;
    };
  };
}
