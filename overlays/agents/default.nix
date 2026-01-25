{ inputs, ... }:
final: prev:
let
  # List of official plugins to include (explicit list for clarity)
  officialPluginNames = [
    "ralph-loop"
    "pr-review-toolkit"
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
      chmod -R u+w "$out"
      patchShebangs "$out"
      runHook postInstall
    '';
  };

  pluginPath = name: "${patchedPlugins}/plugins/${name}";

  # Auto-discover skills from the skills/ directory
  skillsDir = ./skills;
  skillFiles = builtins.attrNames (
    final.lib.filterAttrs (name: type: type == "regular" && final.lib.hasSuffix ".md" name) (
      builtins.readDir skillsDir
    )
  );

  # Build a skill plugin from a markdown file
  mkSkill =
    filename:
    let
      name = final.lib.removeSuffix ".md" filename;
      content = builtins.readFile (skillsDir + "/${filename}");
    in
    final.symlinkJoin {
      name = "skill-${name}";
      paths = [
        (final.writeTextDir "skills/${name}/SKILL.md" content)
        (final.writeTextDir ".claude-plugin/plugin.json" ''
          {"name": "${name}", "version": "1.0.0"}
        '')
      ];
    };

  customSkills = map mkSkill skillFiles;
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
      codex
      gemini-cli
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
      (map pluginPath officialPluginNames) ++ [ inputs.claude-plugins-superpowers ] ++ customSkills;
  };
}
