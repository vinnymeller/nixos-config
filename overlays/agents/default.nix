{ inputs, vlib, ... }:
final: prev:
let
  # List of official plugins to include (explicit list for clarity)
  officialPluginNames = [
    "frontend-design"
    "feature-dev"
    "code-review"
    "code-simplifier"
  ];

  # Extract and patch only the plugins we actually use
  patchedPlugins = final.stdenvNoCC.mkDerivation {
    pname = "claude-plugins-patched";
    version = "0";
    src = inputs.claude-plugins-official;
    dontBuild = true;
    nativeBuildInputs = with final; [
      bash
      coreutils
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/plugins"
      ${final.lib.concatMapStringsSep "\n" (name: ''
        cp -R "./plugins/${name}" "$out/plugins/"
      '') officialPluginNames}
      cp -R ".claude-plugin" "$out/"
      chmod -R u+w "$out"
      patchShebangs "$out"
      runHook postInstall
    '';
  };

  pluginPath = name: "${patchedPlugins}/plugins/${name}";

in
{
  claude-code = inputs.wrapper-modules.wrappers.claude-code.wrap {
    pkgs = final;
    package = final.llm-agents.claude-code;
    envDefault.DISABLE_TELEMETRY = null;
    extraPackages =
      with final;
      [
        nodejs
        libnotify
        jq
        bash
        final.llm-agents.codex
      ]
      ++ (vlib.sharedDeps final).lsps;
    mcpConfig = import ./mcp.nix { pkgs = final; };
    strictMcpConfig = false;
    settings = import ./claudeSettings.nix { pkgs = final; };
    flags = {
      "--append-system-prompt" = ''
        ## Extra Guidelines
        - ALWAYS make aggressive use of subagents where it makes sense.
        - NEVER try running git commands that modify state (e.g. commit, push, rebase, reset). I will handle all git operations myself.
        - When in plan mode or otherwise creating a plan file, ALWAYS be very detailed. Before starting work, we will most likely clear all prior context, and may send the plan to another agent for review. Thus, the plan should be as detailed as needed to be completely clear, self-documenting, and actionable on its own. You should include things like line numbers, decision rationale, tradeoffs already considered, etc, to ensure the agents who review or execute the plan don't need to do extensive research upon reading the plan.
        - When in plan mode or otherwise creating a plan file, when switching tasks/context, NEVER overwrite an existing plan file. Either append to the existing plan file, or create a new plan file for the new task/context. We want to preserve the history of plans and decisions, and avoid losing information by overwriting plan files.
      '';
    };
    pluginDirs = (map pluginPath officialPluginNames) ++ [
      ./customPlug
    ];
  };
}
