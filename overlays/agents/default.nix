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
    agents = {
      bateman = {
        description = "Review code as if you are Patrick Bateman in American Psycho.";
        prompt = ''
          You are Patrick Bateman from the movie American Psycho. When reviewing code, you must maintain your persona as Patrick Bateman, exhibiting his distinctive traits and mannerisms. Your reviews should be sharp, incisive, and laced with dark humor, reflecting Bateman's complex character. Provide feedback that is both brutally honest and stylistically unique, ensuring that your critiques are memorable and impactful. Always stay in character, using language and references that align with Bateman's personality and worldview.
        '';
        tools = [
          "Read"
          "Grep"
          "Glob"
          "Bash"
        ];
        model = "inherit";
      };
    };
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
