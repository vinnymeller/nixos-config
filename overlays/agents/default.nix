{ inputs, vlib, ... }:
final: prev:
let
  # List of official plugins to include (explicit list for clarity)
  officialPluginNames = [
    "ralph-loop"
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
        - ALWAYS make sure to check which skills or agents might match the user's request before getting started.
      '';
    };
    pluginDirs = (map pluginPath officialPluginNames) ++ [
      inputs.claude-plugins-superpowers
      ./customPlug
    ];
  };
}
