{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.secrets;
in
{

  options.mine.secrets = {
    enable = mkEnableOption "Enable useful secrets management.";
  };

  config = mkIf cfg.enable {

    age.secrets.shell-secrets = mkIf cfg.enable {
      file = ../../secrets/shell/secrets.sh.age;
      owner = "root";
      group = "wheel";
      mode = "640";
    };

    environment.shellInit = ''
      source "${config.age.secrets.shell-secrets.path}"
    '';
  };
}
