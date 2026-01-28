{ pkgs }:
let
  npx = "${pkgs.nodejs}/bin/npx";
  codex = "${pkgs.codex}/bin/codex";
in
{
  chrome-devtools = {
    type = "stdio";
    command = npx;
    args = [
      "chrome-devtools-mcp@latest"
      "--executablePath=${pkgs.google-chrome}/bin/google-chrome-stable"
    ];
    env = { };
  };
  codex = {
    type = "stdio";
    command = codex;
    args = [
      "mcp-server"
    ];
    env = { };
  };
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
