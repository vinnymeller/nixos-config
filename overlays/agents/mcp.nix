{ pkgs }:
let
  inherit (pkgs) lib;
  npx = "${pkgs.nodejs}/bin/npx";
in
{ }
// lib.optionalAttrs (pkgs.stdenv.hostPlatform.system != "aarch64-linux") {
  chrome-devtools = {
    type = "stdio";
    command = npx;
    args = [
      "chrome-devtools-mcp@latest"
      "--executablePath=${pkgs.google-chrome}/bin/google-chrome-stable"
    ];
    env = { };
  };
}
