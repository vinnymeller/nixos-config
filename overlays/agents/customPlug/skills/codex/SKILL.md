---
name: codex
description: Invoke OpenAI Codex for its input on a question or task
argument-hint: "[-a {untrusted|on-failure|on-request|never}] [-m <model>] [-s {read-only|workspace-write|danger-full-access}] [-t {low|medium|high|xhigh}] [PROMPT]"
user-invocable: true
---

# Codex Invocation Protocol

## Optional Arguments

The user may pass any of the following optional arguments when invoking the `codex` skill manually:

| Argument | Description |
|----------|-------------|
| `-a {untrusted\|on-failure\|on-request\|never}` | Approval policy for controlling when Codex pauses for approval before executing commands |
| `-m <model>` | Specify the Codex model to use |
| `-s {read-only\|workspace-write\|danger-full-access}` | Scope of Codex access |
| `-t {low\|medium\|high\|xhigh}` | Reasoning effort Codex should use when formulating responses |
| `PROMPT` | The specific question/prompt/task for Codex to address |

The arguments list was defined as follows:

`[-a {untrusted|on-failure|on-request|never}] [-m <model>] [-s {read-only|workspace-write|danger-full-access}] [-t {low|medium|high|xhigh}] [PROMPT]`


The following arguments were provided to the skill invocation:

$ARGUMENTS


## Invocation Guidelines

### How to invoke Codex

Codex is available via its MCP server which provides two tools:

1. `mcp__codex__codex`
   - This tool is for starting a new conversation with Codex. If we aren't already in an active conversation with Codex, you'll always start here.
   - If the user passes any specific arguments (e.g., `-a`, `-m`, `-s`, `-t`, or a prompt), use this tool to invoke Codex with those arguments. Even if this skill is invoked without the specific flag syntax, use the context of the conversation / skill invocation to determine what values to pass to Codex.
      - The `-m` flag maps to the `model` tool parameter. If not provided, use `gpt-5.2-codex`.
      - The `-s` flag maps to the `sandbox` tool parameter. If not provided, generally you should default to `read-only`. However, if you e.g. want Codex to try fixing a bug you're stuck on, or something like that, you can set it to `workspace-write`. `danger-full-access` should only ever be used if the user manually invokes this skill with that flag.
      - The `-a` flag maps to the `approval-policy` tool parameter. If the sandbox mode is set to read-only, this parameter can safely be set to `never`. If the sandbox mode is set to `workspace-write` or `danger-full-access`, this parameter should default to `on-failure`, unless this skill was manually invoked with a different value.
      - The `-t` flag represents the reasoning effort Codex should use. This must be set via the `config` object, e.g. `{"model_reasoning_effort": "high"}`. If not provided, the default heavily depends on context. We should rarely use `low` or `medium`. `high` is probably a safe default if not explicitly set. `xhigh` should be used for complex tasks where a deeply reasoned response is desired (e.g. stuck on a bug, evaluating architecture options, etc).
      - The `PROMPT` maps to the `prompt` tool parameter. Even if this is provided, you should fill this in with a more detailed and complete prompt based on the context of the current conversation. Providing Codex with sufficient initial context is critical to getting it up to speed quickly and producing high-quality results. If we're working on e.g. a specific part of the codebase, provide file references, code snippets, etc as needed. If we're discussing a plan, provide Codex with the full path to the plan file(s).

2. `mcp__codex__codex-reply`
   - This tool is for continuing an existing conversation with Codex. You cannot adjust any parameters like with the previous tool; this is just for sending follow-up messages in an ongoing conversation. The only two parameters are `prompt` and `threadId`.


### When to continue a conversation

This is largely a judgment call based on the context. In some cases, you or the user may simply want Codex's quick opinion on something, in which case, starting a new conversation and relaying the response is likely sufficient.

Sometimes, however, we may want to debate long-term architecture options, or work through a complex bug with Codex. In which case, it may be reasonable to go back and forth over several turns without bringing the user back into the conversation.

For unrelated questions, or when we've moved to a different topic, we should always start a new conversation. *You* are the main agent, so you can always just pass the fresh context to Codex as needed in a new conversation.

### Communication Guidelines

Communicating through files when possible is preferred, but don't go out of your way to create files just so Codex can see them. The go-to example, again, is if we're working on a plan document and getting feedback from Codex. It's simpler and more efficient for you to just provide the path to the plan document instead of copying or summarizing the information in your prompt.

### Context Management

**Note:** If you are a subagent executing this skill, *always* invoke Codex directly, do not spawn another subagent to do so.

For the main conversation agent:

Consider using a `general-purpose` subagent to invoke Codex when:
- The conversation is expected to be self-contained and won't benefit much main conversation context
- You expect several back-and-forth messages
- A summary of the outcome is sufficient
- If you choose this route, instruct the subagent to return the final `threadId` in its summary. To continue the conversation with Codex, prefer resuming the subagent via its `agentId` instead of directly invoking Codex with the `threadId`. The subagent will have better context of the prior conversation.

Invoke codex directly as the main agent when:
- The question is quick (1-2 turns)
- Codex needs to understand WHY we made certain decisions (conversation context is important)
- Codex's response may immediately inform your next action(s)
