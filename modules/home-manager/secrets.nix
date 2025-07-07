{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.secrets;
in
{
  imports = [
    inputs.ragenix.homeManagerModules.default
  ];

  options.mine.secrets = {
    enable = mkEnableOption "Enable useful secrets management.";
  };

  config = mkIf cfg.enable {

    age.secrets.shell-secrets = mkIf cfg.enable {
      file = ../../secrets/shell/secrets.sh.age;
      mode = "440";
    };

    programs.zsh.envExtra =
      let
        secretPath = config.age.secrets.shell-secrets.path;
      in
      ''
        if [ -f "${secretPath}" ] && [ -r "${secretPath}" ]; then
          source "${secretPath}"
        fi
      '';
  };
}
