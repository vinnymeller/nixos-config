---
name: peer-review
description: Get perspectives from Gemini and/or Codex on a question, then synthesize a recommendation
user-invocable: true
allowed-tools: Bash(codex exec --sandbox read-only:*), Bash(gemini -y -o text --sandbox:*), WebSearch, WebFetch, Read,  Grep, Glob
---

# Peer Review Skill

Based on the user's question or task, you will spawn Codex and/or Gemini subagents to get their respective analyses or perspectives on the topic at hand.

## Process
1. **Think about users question or task** and do any necessary context gathering:
   - If the user asks you to evaluate the current plan, make sure you have the plan details first, in order to provide accurate details to both agents.
   - If the user asks a question about the codebase, ensure you have the relevant code snippets or file paths ready to provide context to both agents. In addition to just providing a summary or snippet, if we're talking about specific files or code sections, provide file paths and potentially even line numbers to help them locate the relevant code quickly.
   - **ALWAYS** specify in your context to subagents when we are talking about questions related to our current codebase, as they can use their own tools to read and explore further if they choose to - but they won't know that if they think we're talking about some arbitrary or hypothetical codebase.

2. **Launch agents** using the Task tool with `subagent_type: "customPlug:gemini-analyzer"` and `subagent_type: "customPlug:codex-analyzer"`, respectively:
   - If the user doesn't specify which agent to use, use both.
   - Both subagents already know how to invoke their respective CLIs with the correct flags so just provide the prompt to them.
   - If either agent fails, retry once. If they fail again, just report the failure to the user.

3. **Wait for both to complete** and collect their responses

4. **Analyze responses** from both agents:
   - Synthesize the key points from each agent's response, and think about your position given their perspectives.
   - If there is significant disagreement between the agents invoked and yourself, repeat steps 1-3, providing the differing perspectives as context to get more clarity. **DO NOT** do this more than three times at most.
   - Once you either have consensus or have already gone through 3 iterations of subagent invocations, proceed to step 5.

4. **Summarize to user**:
   - Brief summary of Gemini's perspective (2-3 sentences)
   - Brief summary of Codex's perspective (2-3 sentences)
   - Your own perspective (2-3 sentences)
   - **Final recommendation** (detailed analysis based on all information gathered and your own final judgment)

## Example Output Format

```
## Gemini's Take
[Brief summary of Gemini's response]

## Codex's Take
[Brief summary of Codex's response]

## My Take
[Your own analysis]

## Recommendation
[Your synthesized recommendation considering all perspectives]
```

## Implementation Notes

- Use `run_in_background: false` so you wait for results
- Both agents should run in parallel (single message with two Task calls)
- Do NOT create any files - output everything inline to the conversation
