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
        immich.enable = mkDefault false;
        restic = {
          enable = mkDefault false;
          rcloneConfAge = ../../secrets/vinnix/rclone.conf.age;
          passwordFileAge = ../../secrets/vinnix/restic-password.age;
          providers = {
            backblaze.target = "backblaze:vinnix-restic";
            storj.target = "storj:restic";
          };
          onFailure = {
            enable = true;
            notifyUser = "vinny";
          };
        };
        booklore.enable = mkDefault false;
        vtt.enable = mkDefault true;
      };
      networking.enable = mkDefault true;
      nix.enable = mkDefault true;
    };
  };
}
