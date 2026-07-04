# smooth — Identify and fix friction, clunkiness, and rough edges in recent execution

> **Trigger**: `smooth` | **Purpose**: Identify and fix friction, clunkiness, and rough edges in recent execution to make the next run better
> **Context file**: [this file](http://${SERVER_HOST}:8080/editor/opencode/agents/context/smooth-instructions.md)
> **Template**: [trigger-protocol-template.md](http://${SERVER_HOST}:8080/editor/opencode/agents/context/trigger-protocol-template.md)
> **When to use**: When something worked but felt rough — too many steps, unnecessary questions, wasted tokens, or the agent fumbled before getting it right

## Phase 0: Clarifying Questions

Ask via question tool. Skip if user provides a target (e.g., `smooth blog publish` or `smooth dashboard`).

**Question**: "What felt rough?"

| Option | Focus |
|--------|-------|
| **Last task** (Recommended) | Polish the most recently completed task |
| **A specific workflow** | Name a workflow to smooth (e.g., `smooth blog pipeline`) |
| **A skill** | Smooth a skill's execution path |
| **A trigger** | Smooth how a trigger runs (e.g., `smooth ?`) |
| **Auto-detect** | Scan session for the roughest execution and fix it |

**Question 2** (only if needed): "What kind of roughness?"

| Option | Type |
|--------|------|
| **Too many questions** | Agent asked obvious things, should have known from context |
| **Wrong order** | Steps happened in a suboptimal sequence |
| **Unnecessary steps** | Redundant reads, duplicate checks, wasted tool calls |
| **Missing context** | Agent didn't load something it should have |
| **Error recovery** | Errors that could have been prevented |
| **Everything** (Recommended) | Full polish pass |

## Phase 1: Read State

Gather execution evidence silently:

| Source | What to Extract |
|--------|-----------------|
| Current session conversation | Every tool call, decision point, user correction |
| Tool call counts | How many reads/writes/bash/skill loads happened |
| User corrections | Where did the user say "no", "not that", "different" |
| Retries | Where did the agent retry or re-do something |
| Timing gaps | Long pauses between steps (indicates confusion) |
| Related skill files | The skill's current instructions (if a skill is targeted) |
| Related trigger protocol | The trigger's current phases (if a trigger is targeted) |

## Phase 2: Friction Analysis

Map each point of friction:

| Friction Type | Signals | Impact |
|---------------|---------|--------|
| **Over-asking** | Agent asked 3+ clarifying questions for a clear task | Wastes user time, breaks flow |
| **Under-preparing** | Agent started without reading required context | Leads to errors and rework |
| **Wrong sequencing** | Steps happened out of optimal order | Extra reads, wasted tokens |
| **Redundant work** | Same file read twice, same check run twice | Wastes tokens and time |
| **Premature output** | Agent produced output before gathering all inputs | Requires rework |
| **Missing pre-flight** | No Docker/health check before container operation | Preventable failures |
| **Verbose responses** | Agent explained what it was doing instead of doing it | Wastes tokens, slow UX |
| **Skill not loaded** | Agent did manually what a skill automates | Reinvents the wheel |

## Phase 3: Prioritise Fixes

Classify each friction point:

| Tag | When to Use |
|-----|-------------|
| **Critical** | Friction that causes errors or failures |
| **High** | Friction that wastes significant tokens or time |
| **Medium** | Friction that's annoying but doesn't block progress |
| **Low** | Minor polish — nice to have |

## Phase 4: Present Polish Plan

Present via question tool with multi-select:

```
Found N friction points for {target}:
- [ ] 1. {Friction} [Critical] — {fix description} (saves ~{tokens} tokens)
- [ ] 2. {Friction} [High] — {fix description} (saves ~{tokens} tokens)
...
- [ ] Skip — just show the analysis
```

For each fix, specify:
- **Target file** — which context file, skill, or protocol to edit
- **The fix** — smallest possible change
- **Expected savings** — tokens, time, or steps saved

## Phase 5: Apply Polish

For each approved fix:

1. **Read** the target file
2. **Apply** the smallest edit that fixes the friction
3. **Verify** the change makes sense in context

Common fix patterns:

| Friction | Fix Location | Fix Type |
|----------|-------------|----------|
| Over-asking | Protocol Phase 0 | Add skip conditions, provide defaults |
| Missing pre-flight | Protocol Phase 1 | Add required reads before execution |
| Wrong sequence | Protocol phases | Reorder steps in the protocol |
| Redundant work | Skill instructions | Add "don't re-read files you already have" |
| Verbose responses | AGENTS.md or skill | Add "no preamble" rules |
| Skill not loaded | Protocol Phase 1 | Add skill discovery step |

## Phase 6: Confirm & Record

1. **Summarise** what was smoothed and expected improvements
2. **Record trigger**: `record_trigger.py smooth --context "{what was polished}"`
3. **Capture experience**: `capture_conversation.py "Smoothed {target}" --type experience --tags "smooth,polish,{target_name}"`
4. **Offer follow-up**: `flow {target}` to verify the next execution is smoother

## Smoothness Score

Rate the before/after:

| Score | Meaning |
|-------|---------|
| 5/5 | One-shot execution, no corrections needed |
| 4/5 | Minor adjustments, no errors |
| 3/5 | Some back-and-forth but task completed |
| 2/5 | Multiple retries, user had to redirect |
| 1/5 | Task failed or was abandoned |

Target: every smoothed workflow should score 4+ on next execution.

## Anti-Patterns

| Pattern | Fix |
|---------|-----|
| Smoothing without evidence | Always analyse actual execution first |
| Rewriting entire protocols | Smallest edit — add a rule, reorder a step |
| Ignoring token cost | Every fix should reduce tokens or steps |
| No follow-up verification | Offer `flow` to validate the improvement |
| Over-optimising | If it scores 4/5, it's smooth enough — move on |
| Only fixing errors | Smooth = prevent friction, not just fix failures |
