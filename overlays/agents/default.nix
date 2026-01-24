{ inputs, ... }:
final: prev: {
  claude-code = inputs.wrapper-modules.wrappers.claude-code.wrap {
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
    pluginDirs =
      let
        official' = pname: "${inputs.claude-plugins-official}/plugins/${pname}";
        official = map official' [
          "ralph-loop"
          "pr-review-toolkit"
          "frontend-design"
          "feature-dev"
          "code-review"
          "code-simplifier"
        ];
      in
      [
        "${inputs.claude-plugins-superpowers}"
        "${inputs.claude-plugins-gsd}"
      ]
      ++ official;
  };
}
