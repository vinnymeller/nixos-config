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

    age.secrets.shell-secrets.file = mkIf cfg.useSecrets ../../secrets/shell/secrets.sh.age;

    environment.shellInit = ''
      source "${config.age.secrets.shell-secrets.path}"
    '';
  };
}
