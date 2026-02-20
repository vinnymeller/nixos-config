{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.mine.services.vtt;
in
{

  options.mine.services.vtt = {
    enable = mkEnableOption "Enable VTT (voice-to-text)";
    users = mkOption {
      type = types.listOf types.str;
      default = [ "vinny" ];
      description = "Users to grant ydotool access for VTT.";
    };
  };

  config = mkIf cfg.enable {

    programs.ydotool.enable = true;

    users.users = builtins.listToAttrs (
      map (user: {
        name = user;
        value = {
          extraGroups = [ config.programs.ydotool.group ];
        };
      }) cfg.users
    );

    age.secrets.vtt-gemini = {
      file = ../../secrets/vtt/gemini.age;
      group = config.programs.ydotool.group;
      mode = "0440";
    };

    environment.systemPackages = [
      (pkgs.callPackage ../../pkgs/vtt/default.nix {
        geminiKeyFile = config.age.secrets.vtt-gemini.path;
      })
    ];

  };
}
