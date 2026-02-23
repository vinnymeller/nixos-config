{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.mine.services.immich;
in
{

  options.mine.services.immich = {
    enable = mkEnableOption "Enable Immich";
    user = mkOption {
      type = types.str;
      default = "immich";
      description = "User to run Immich under.";
    };
    group = mkOption {
      type = types.str;
      default = "immich";
      description = "Group to run Immich under.";
    };
  };

  config = mkIf cfg.enable {

    age.secrets.immich = {
      file = ../../secrets/vinnix/immich.age;
      owner = cfg.user;
      group = cfg.group;
      mode = "0400";
    };

    services.immich = {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      accelerationDevices = null; # null gives access to all devices
      secretsFile = config.age.secrets.immich.path;
      host = "0.0.0.0";
    };

    mine.services.offsiteSync.jobs.immich = {
      source = config.services.immich.mediaLocation;
      afterUnits = [ "immich-server.service" ];
    };

    users.users.${cfg.user}.extraGroups = [
      "video"
      "render"
    ];

  };
}
