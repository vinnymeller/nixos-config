{ inputs, vlib, ... }:
final: prev:
let
  officialPluginNames = [
    "frontend-design"
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
        - Do not try running git commands that modify state (e.g. commit, push, rebase, reset). I will handle all git operations myself.
        - When in plan mode or otherwise creating a plan file, ALWAYS be very detailed. Before starting work, we will most likely clear all prior context, and may send the plan to another agent for review. Thus, the plan should be as detailed as needed to be completely clear, self-documenting, and actionable on its own. You should include things like line numbers, decision rationale, tradeoffs already considered, etc, to ensure the agents who review or execute the plan don't need to do extensive research upon reading the plan.
        - When switching tasks or contexts during planning mode, `mv` the existing plan file to a new name that gives an indication as to which task it corresponds to, e.g. `mv plans/sparkling-dazzling-butterfly.md plans/old/user-auth-refactor.md`.
        - You are inherently extremely flawed at estimating timelines and effort. This is due to the bulk of your training data being based on human text. For context, we routinely complete tasks together in hours that you estimate will take weeks. Do not factor your flawed estimates into which course of action we should take. Always default to the most architecturally sound and maintainable course of action given the overall project context.
        - Implementing code is cheap. Don't fear large refactors or changes if they will lead to a better overall codebase. Time spent ensuring we have a good, thorough plan is almost always time well spent, and time working around iffy or outdated decisions is almost always time wasted.
        - When creating a plan, always keep behavior front and center. ALWAYS explicitly include the tests we'll use to verify in the plan to ensure they're not skipped or an afterthought. Tests verify the behavior of the system, and when creating a plan, we are creating a specification. Many big issues can be avoided by thinking about the behavior and how to verify it up front. Where there isn't clarity about what behavior should look like, ask me for clarification until it's clear.
      '';
    };
    pluginDirs = (map pluginPath officialPluginNames) ++ [
      ./customPlug
    ];
  };
}
