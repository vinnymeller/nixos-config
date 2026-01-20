{ pkgs }:
let
  npx = "${pkgs.nodejs}/bin/npx";
  uvx = "${pkgs.uv}/bin/uvx";
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
  pal = {
    type = "stdio";
    command = uvx;
    args = [
      "--from"
      "git+https://github.com/BeehiveInnovations/pal-mcp-server.git"
      "pal-mcp-server"
    ];
    env = { };
  };
}
