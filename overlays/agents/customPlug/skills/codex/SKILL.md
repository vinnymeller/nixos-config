---
name: codex
description: Invoke OpenAI Codex for its input on a question or task
argument-hint: "[-m <model>] [-s {read-only|workspace-write|danger-full-access}] [-t {low|medium|high|xhigh}] [--full-auto] [PROMPT]"
allowed-tools: Bash(codex:*)
user-invocable: true
---

# Codex Invocation Protocol

## Optional Arguments

| Argument | Description |
|----------|-------------|
| `-m <model>` | Specify the Codex model to use |
| `-s {read-only\|workspace-write\|danger-full-access}` | Sandbox policy for model-generated shell commands |
| `-t {low\|medium\|high\|xhigh}` | Reasoning effort Codex should use |
| `--full-auto` | Convenience alias for `-s workspace-write` with relaxed approval |
| `PROMPT` | The specific question/prompt/task for Codex to address |

The following arguments were provided to the skill invocation:

$ARGUMENTS


## How to invoke Codex

Codex is invoked via `codex exec` in Bash.

### Starting a new conversation

Build the command from these flags:

- **`-m <model>`**: Default `gpt-5.3-codex`.
- **`-s <sandbox>`**: Default `read-only`. Use `workspace-write` when Codex should attempt fixes. `danger-full-access` only if explicitly requested by the user.
- **`--full-auto`**: Sets `workspace-write` with relaxed approval. Do not combine with `-s`.
- **`-c model_reasoning_effort=<level>`**: Default `high`. Rarely use `low`/`medium`. Use `xhigh` only for the most complex tasks (e.g., stuck on a bug after previous `high`-effort attempts failed).
- **`-c model_reasoning_summary=none`**: Always include to suppress noisy reasoning summaries. Pass `auto` instead only if seeing Codex's reasoning process would genuinely help (rare).
- **`PROMPT`**: Even if a prompt is provided, enrich it with context from the current conversation — file references, code snippets, plan file paths, etc. Refer to files by path rather than copying content when possible.
- **`-o <file>`** *(optional)*: Use `-o /tmp/codex-output.md` only if you expect a longer back-and-forth where a conversation log would be useful. Normally unnecessary — Bash captures stdout.

Do **not** use `--json` — it floods stdout with noisy JSONL events.

**Examples:**

```bash
# Read-only question
codex exec -m gpt-5.3-codex -s read-only -c model_reasoning_effort=high -c model_reasoning_summary=none "Explain how the auth module works"

# Full-auto debugging
codex exec -m gpt-5.3-codex --full-auto -c model_reasoning_effort=xhigh -c model_reasoning_summary=none "Fix the failing test in src/auth/login.test.ts"
```

### Continuing a conversation

**Always use the session ID** — never `--last`, since multiple Claude instances may be talking to Codex concurrently.

```bash
codex exec resume <SESSION_ID> "Follow-up question here"
```

### Session ID tracking

The session ID is printed to stdout as `session id: <UUID>`. You **must** extract and store it after every `codex exec` call — it is required for `resume`.

### When to start new vs. continue

Continue with `resume` for extended discussions (architecture debates, multi-step debugging). Start a new conversation when the topic changes. For quick one-off questions, a single invocation is usually sufficient.

## Context Management

If you are a subagent, invoke Codex directly via Bash — do not spawn another subagent.

For the main conversation agent, consider using a `general-purpose` subagent when the Codex conversation is self-contained, multi-turn, and a summary suffices. Instruct the subagent to return the session ID so the conversation can be resumed later via the subagent's `agentId`. Invoke Codex directly when the question is quick, conversation context matters, or the response will immediately inform your next action.
