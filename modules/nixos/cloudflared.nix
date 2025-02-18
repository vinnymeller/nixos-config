{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.cloudflared;
in
{
  options.mine.services.cloudflared = {
    enable = mkEnableOption "Enable cloudflared service.";
    moves.enable = mkEnableOption "Enable cloudflared tunnels for moves app.";
  };

  config = mkIf cfg.enable {
    age.secrets.cloudflared-moves-creds = mkIf cfg.moves.enable {
      file = ../../secrets/cloudflared/moves/credentials.json.age;
      group = config.services.cloudflared.group;
      owner = config.services.cloudflared.user;
    };
    services.cloudflared = {
      enable = true;
      tunnels = {
        "96279372-faa6-4f6d-8ccb-1d7552202fb5" = mkIf cfg.moves.enable {
          credentialsFile = config.age.secrets.cloudflared-moves-creds.path;
          ingress = {
            "moves.social" = {
              service = "http://localhost:4173"; # dont judge me
            };
            "admin.moves.social" = {
              service = "http://localhost:4174";
            };
            "api.moves.social" = {
              service = "http://localhost:5001";
            };
          };
          default = "http_status:404";
        };
      };
    };

  };
}
