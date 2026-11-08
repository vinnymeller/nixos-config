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

  # Shared by the PreCompact hook (in claudeSettings.nix) and the agent's PATH
  # below, so `claude-context-archive save` and the agent's `search`/`list`
  # calls resolve to the exact same tool.
  contextArchive = import ./contextArchive.nix { pkgs = final; };

  intentGate = import ./intentGate.nix {
    pkgs = final;
    inherit contextArchive;
    judgeClaude = final.llm-agents.claude-code;
  };

in
rec {
  claude-context-archive = contextArchive;
  claude-intent-gate = intentGate;

  # The intent-keeper (customPlug/agents/intent-keeper.md) in its own session,
  # e.g. a tmux pane next to the agents it watches. CLAUDE_INTENT_KEEPER=1 keeps
  # its own turns out of the event log and exempts it from the question gates.
  # Uses whichever `claude` is on PATH (claude-code or claude-code-work).
  claude-intent-keeper = final.writeShellApplication {
    name = "claude-intent-keeper";
    text = ''
      export CLAUDE_INTENT_KEEPER=1
      exec claude --agent xv:intent-keeper -n intent-keeper "$@" \
        "Start: read the user's intent, the active plans and the review, then begin watching the project's events."
    '';
  };

  claude-code = inputs.wrapper-modules.wrappers.claude-code.wrap {
    pkgs = final;
    package = final.llm-agents.claude-code;
    envDefault.DISABLE_TELEMETRY = null;
    runtimePkgs =
      with final;
      [
        nodejs
        libnotify
        jq
        bash
        contextArchive
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
        - When creating a plan, always keep behavior front and center. ALWAYS explicitly include the tests we'll use to verify in the plan to ensure they're not skipped or an afterthought. Tests verify the behavior of the system, and when creating a plan, we are creating a specification. Many big issues can be avoided by thinking about the behavior and how to verify it up front. While planning, where my words don't settle what the behavior should be, ask me until it's clear: behavior is the one thing worth stopping for before work starts.
        - I review architecture and decisions, plus a few important pieces of code, rather than every line. So once work is underway, make decisions yourself instead of stopping to ask me, as long as they're consistent with what I've said (check `claude-context-archive intent` before assuming I haven't said). Record every decision I might want to weigh in on with `claude-context-archive decide "<what you decided>" --basis "<my words it rests on, or 'not covered'>" --undo "<how to reverse it>"` (add `--by <your name>` if you are a subagent or teammate): architecture and data-model choices, behavior the plan didn't specify, new dependencies, tradeoffs, and any deviation from the plan. Mark code I should read myself with `claude-context-archive flag <file[:lines]> "<why>"`, e.g. security, money, data migrations, or the core of a design. Stop and ask me only when the choice goes beyond or contradicts what I've said, when it's hard to reverse or reaches outside the repo (deploys, deleting or migrating real data, sending anything, spending money, git), or when my own messages conflict. Agents may challenge and reverse each other's decisions on those grounds; record a reversal with `decide ... --reverses <id>`. Hooks may send a question or a plan back to you with the reason; treat that as my answer.
        - After a context compaction, earlier details from this session may no longer be in your context. Every conversation's full transcript, including everything before a compaction and the conversations of other sessions in this project, is readable with `claude-context-archive` (regexes are case-insensitive):
          - `claude-context-archive search '<regex>'` searches THIS conversation's full history. Reach for it first, e.g. when you know you worked through something earlier this session but have lost the specifics.
          - `claude-context-archive search-project '<regex>'` searches every conversation in the current project, running or finished. Use it when the detail likely came from a different or earlier session, e.g. the user says they discussed it with another agent.
          - `claude-context-archive intent` prints only what the user typed (and their answers to questions) across this project's running sessions, oldest first; `--since 2d` widens it to recent conversations, `--session <id|name>` narrows it to one. Use it to check a plan, a decision, or another agent's work against the user's own words rather than an agent's paraphrase of them.
          - `claude-context-archive peers` lists the running sessions in this project and their recently active subagents, with status and what each last said. A session's name is its SendMessage address.
          - `claude-context-archive review` shows the decisions and flags recorded since my last commit, plus the structural changes in the working tree (dependencies, migrations, new and deleted files); `--since 2d` or `--all` change the scope. Use it when I ask what was decided, or before you report a substantial piece of work as done.
          - `claude-context-archive list` lists this project's conversations, newest first, marking the current one.
          - Search results print as `file:line: match`. To read the surrounding turns, run `claude-context-archive show <file> <line> [radius]` (default 5 entries either side); `show` also takes a session id or its first 8 characters in place of the file. Transcripts are raw JSONL, so you can also `rg` or `jq` one directly. Prefer targeted patterns (a filename, symbol, error string, or decision keyword) over broad terms.
      '';
    };
    pluginDirs = (map pluginPath officialPluginNames) ++ [
      ./customPlug
    ];
  };

  claude-code-work = claude-code.wrap {
    pluginDirs = [ "${inputs.camoag-os}/plugins/camo-os" ];
  };
}
