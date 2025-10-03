{ pkgs }:
{
  chrome-devtools = {
    type = "stdio";
    command = "npx";
    args = [
      "chrome-devtools-mcp@latest"
      "--executablePath=${pkgs.google-chrome}/bin/google-chrome-stable"
    ];
    env = { };
  };
  context7 = {
    type = "stdio";
    command = "npx";
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
  zen = {
    type = "stdio";
    command = "uvx";
    args = [
      "--from"
      "git+https://github.com/BeehiveInnovations/zen-mcp-server.git"
      "zen-mcp-server"
    ];
    env = { };
  };
}
