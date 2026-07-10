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

- **`-m <model>`**: Default `gpt-5.6-sol`.
- **`-s <sandbox>`**: Default `read-only`. Use `workspace-write` when Codex should attempt fixes. `danger-full-access` only if explicitly requested by the user.
- **`--full-auto`**: Sets `workspace-write` with relaxed approval. Do not combine with `-s`.
- **`-c model_reasoning_effort=<level>`**: Default `high`. Rarely use `low`/`medium`. Use `xhigh` only for the most complex tasks (e.g., stuck on a bug after previous `high`-effort attempts failed).
- **`-c model_reasoning_summary=none`**: Always include to suppress noisy reasoning summaries. Pass `auto` instead only if seeing Codex's reasoning process would genuinely help (rare).
- **`PROMPT`**: Even if a prompt is provided, enrich it with context from the current conversation — file references, code snippets, plan file paths, etc. Refer to files by path rather than copying content when possible.
- **`-o <file>`**: Use `-o /tmp/codex-output-<identifier>.md` every time you invoke codex. Do not do anything too fancy with pipes or redirection as it'll be likely to cause issues.

Do **not** use `--json` — it floods stdout with noisy JSONL events.

**Examples:**

```bash
# Read-only question
codex exec -m gpt-5.6-sol -s read-only -c model_reasoning_effort=high -c model_reasoning_summary=none "Explain how the auth module works"

# Full-auto debugging
codex exec -m gpt-5.6-sol --full-auto -c model_reasoning_effort=xhigh -c model_reasoning_summary=none "Fix the failing test in src/auth/login.test.ts"
```

### Continuing a conversation

**Always use the session ID** — never `--last`, since multiple Claude instances may be talking to Codex concurrently. Re-specify the model with `-m`, and pass `-o` again to capture the reply.

**`resume` does NOT accept `-s`/`--sandbox`** — it inherits the original session's sandbox. Passing `-s` errors with `unexpected argument '-s' found`. (`-m`, `-c`, and `-o` are accepted.) So a resume is:

```bash
codex exec resume <SESSION_ID> -m gpt-5.6-sol -c model_reasoning_summary=none -o /tmp/codex-output-<id>.md "Follow-up question here" </dev/null
```

**Resume cannot rescue a run that died from context exhaustion** (see "Output reliability" below): the resumed session reloads the full prior context, so if the original run filled the context window there is no room to generate and the resume also produces nothing (clean exit, empty output). Prevent the exhaustion on the first run — don't rely on resume to bail you out.

### Session ID tracking

The session ID is printed to stdout as `session id: <UUID>`. You **must** extract and store it after every `codex exec` call — it is required for `resume`.

### When to start new vs. continue

Continue with `resume` for extended discussions (architecture debates, multi-step debugging). Start a new conversation when the topic changes. For quick one-off questions, a single invocation is usually sufficient.

## Context Management

If you are a subagent, invoke Codex directly via Bash — do not spawn another subagent.

For the main conversation agent, consider using a `general-purpose` subagent when the Codex conversation is self-contained, multi-turn, and a summary suffices. Instruct the subagent to return the session ID so the conversation can be resumed later via the subagent's `agentId`. Invoke Codex directly when the question is quick, conversation context matters, or the response will immediately inform your next action.

### Always close stdin

**Critical**: every `codex exec` invocation MUST have `</dev/null` redirecting stdin, even though the prompt is passed as a
positional argument. If you don't, codex prints `Reading additional input from stdin...` and waits forever for EOF on the inherited
shell stdin — the run hangs indefinitely with no progress and no output file.

```bash
# WRONG — hangs on stdin
codex exec -m gpt-5.6-sol -s read-only -c model_reasoning_effort=high -c model_reasoning_summary=none -o /tmp/codex-output-X.md "$(cat
/tmp/codex-prompt-X.md)"

# CORRECT — stdin closed
codex exec -m gpt-5.6-sol -s read-only -c model_reasoning_effort=high -c model_reasoning_summary=none -o /tmp/codex-output-X.md "$(cat
/tmp/codex-prompt-X.md)" </dev/null
```

For background launches, the full pattern is:

```bash
codex exec ... -o /tmp/codex-output-X.md "$(cat /tmp/codex-prompt-X.md)" </dev/null > /tmp/codex-stdout-X.log 2>&1 &
echo "spawned pid=$!"
```

`run_in_background: true` on the Bash tool does **not** close stdin on its own — the `</dev/null` redirect is required either way.
The same applies to `codex exec resume <SESSION_ID> "..."`.

### Prefer a prompt file over an inline heredoc

For non-trivial prompts, write the prompt to `/tmp/codex-prompt-<identifier>.md` first via the Write tool, then pass it as `"$(cat
/tmp/codex-prompt-<identifier>.md)"`. This keeps the `ps` output readable, sidesteps quoting/escaping bugs in long heredocs, and lets
 you inspect the exact prompt that was sent.

### Detecting a stdin hang

If `/tmp/codex-output-<id>.md` doesn't exist after ~1 minute and the stdout log shows `Reading additional input from stdin...` as the
 last line, codex is hung on stdin. Kill the codex process tree and relaunch with `</dev/null` appended. Don't wait it out — it will
never recover.

## Output reliability — the `-o` file, and why big tasks silently produce nothing

`-o`/`--output-last-message` writes the agent's **final message only**, and only if the run reaches one. **A missing `-o` file after an `exit 0` run means the run was cut off before producing a final message — NOT a flag problem.** Always verify the file exists and is non-empty; never trust the exit code alone. (Confirm the flag itself works with a trivial prompt — `-o` reliably writes `HELLO` for a one-line reply on both `exec` and `resume`.)

**The dominant failure mode for review/analysis tasks is context exhaustion.** When codex reads many large files — `cat`/`nl`/`sed` over 1000+-line slices, repo-wide `rg` dumps — it fills the context window before it synthesizes, then terminates with `exit 0` and **no final message** (the stdout log just ends mid-tool-output; no `tokens used` line). There is **no config knob to raise this** — `max_turns`, `exec.max_turns`, `model_max_output_tokens` are all rejected as unknown fields. And resume can't recover it (the near-full context reloads). The only fix is to **not fill the context in the first place.**

**Mitigations (bound the reading, front-load the grounding):**

- **Cap reads in the prompt, explicitly:** "Read at most N lines per file with `sed -n 'A,Bp'`. Do NOT `cat` whole files or run repo-wide `rg`. If tempted to read more, stop and reason from what you have."
- **Provide grounded `file:line` anchors in the prompt** so codex *verifies/judges* rather than *re-derives* — re-grounding is what burns the context. For a plan review, tell it the anchors are already verified and its job is design judgment + gap-finding.
- **Keep scope tight; split a huge review into focused passes** rather than one "verify everything" mega-prompt.
- **End the prompt with an explicit finish instruction:** "Then write your review as your FINAL MESSAGE. Budget your reading so you finish."
- A well-bounded review of a ~200-line plan finishes in one `exec` and writes `-o` cleanly; an unbounded "read the plan and verify all claims against the whole codebase" reliably dies. The difference is entirely how much file content you let it pull into context.
