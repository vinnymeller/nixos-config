{
  options =
    { lib, ... }:
    {
      geminiKeyFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the Gemini API key .age file for VTT.";
      };
    };

  nixos =
    {
      cfg,
      config,
      eachUser,
      lib,
      pkgs,
      ...
    }:
    {
      programs.ydotool.enable = lib.mkDefault true;

      users.users = eachUser {
        extraGroups = [ config.programs.ydotool.group ];
      };

      age.secrets.vtt-gemini = {
        file = cfg.geminiKeyFile;
        group = config.programs.ydotool.group;
        mode = "0440";
      };

      environment.systemPackages = [
        (pkgs.vtt { geminiKeyFile = config.age.secrets.vtt-gemini.path; })
      ];
    };
}
