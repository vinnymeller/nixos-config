{ inputs, ... }:
final: prev:
let
  claudePluginsPatched = final.stdenvNoCC.mkDerivation {
    pname = "claude-plugins-official-patched";
    version = "0";
    src = inputs.claude-plugins-official;
    dontBuild = true;
    nativeBuildInputs = with final; [
      bash
      coreutils
    ];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -R . "$out/"
      chmod -R u+w "$out"

      patchShebangs "$out"

      runHook postInstall
    '';
  };
in
{
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
    flags = {
      "--append-system-prompt" = ''
        ## Extra Guidelines
        - ALWAYS make aggressive use of subagents where it makes sense.
        - NEVER try running git commands that modify state (e.g. commit, push, rebase, reset). I will handle all git operations myself.
        - ALWAYS make sure to check which skills or agents might match the user's request before getting started.
      '';
    };
    pluginDirs =
      let
        official' = pname: "${claudePluginsPatched}/plugins/${pname}";
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
        inputs.claude-plugins-superpowers
      ]
      ++ official;
  };
}
