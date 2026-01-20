{ inputs, ... }:
{
  claude-code = final: prev: {
    claude-code = inputs.wrappers.wrappedModules.claude-code.wrap {
      pkgs = final;
      package = final.llm-agents.claude-code;
      extraPackages = with final; [
        nodejs
        uv
        bun
        python3
        libnotify
        jq
        bash
      ];
      mcpConfig = import ./mcp.nix { pkgs = final; };
      strictMcpConfig = false;
      settings = import ./claudeSettings.nix { pkgs = final; };
    };
  };
}
