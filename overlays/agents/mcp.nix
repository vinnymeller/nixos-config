{ pkgs }:
let
  inherit (pkgs) lib;
  npx = "${pkgs.nodejs}/bin/npx";
in
{
  context7 = {
    type = "stdio";
    command = npx;
    args = [
      "-y"
      "@upstash/context7-mcp"
    ];
    env = { };
  };
  github = {
    type = "stdio";
    command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
    args = [
      "stdio"
    ];
    env = { };
  };
}
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
