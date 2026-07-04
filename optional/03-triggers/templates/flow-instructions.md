# flow — Trace, document, and analyse how tasks execute from request to completion

> **Trigger**: `flow` | **Purpose**: Trace, document, and improve how tasks execute from request to completion
> **Context file**: [this file](http://${SERVER_HOST}:8080/editor/opencode/agents/context/flow-instructions.md)
> **Template**: [trigger-protocol-template.md](http://${SERVER_HOST}:8080/editor/opencode/agents/context/trigger-protocol-template.md)
> **When to use**: After completing a task, when execution felt wrong, or to review how something ran

## Phase 0: Clarifying Questions

Ask via question tool. Skip if user provides a target (e.g., `flow last session` or `flow blog publish`).

**Question**: "What do you want to trace?"

| Option | Scope |
|--------|-------|
| **Last session** (Recommended) | Analyse the most recent completed session |
| **Last task** | Analyse just the last task in current session |
| **Specific task** | Name a task to trace (e.g., `flow blog pipeline`) |
| **Current session** | Live trace of what's happening now |
| **Comparison** | Compare two approaches to the same task |

## Phase 1: Read State

Gather execution data silently:

| Source | What to Extract |
|--------|-----------------|
| Current session conversation | Tool calls, decisions, errors, timing |
| `${HOME}/.local/share/opencode/log/` | Session logs for past sessions |
| `skill_event.py` logs | Skill invocations and durations |
| `subagent_wrapper.py --stats` | Subagent dispatch history |
| `record_trigger.py --stats` | Trigger usage patterns |
| `session_quality.py check` | Quality metrics for current session |
| `hybrid_tracker.py flow list --active` | In-progress flows |

## Phase 2: Classify Task Type

Determine what kind of execution happened:

| Category | Signals | Typical Flow |
|-----------|---------|-------------|
| **Conversational** | Multi-turn dialogue, clarifications | USER > AGENT > USER > AGENT |
| **Direct Task** | Single request, clear requirements | USER > AGENT > EXECUTE > COMPLETE |
| **Complex Multi-Step** | Multiple phases, delegation | USER > AGENT > PLAN > DELEGATE > COMPLETE |
| **Research-Heavy** | Information gathering, external sources | USER > AGENT > SEARCH > ANALYZE > COMPLETE |
| **Troubleshooting** | Error diagnosis, iterative fixing | USER > AGENT > DIAGNOSE > FIX > VERIFY > COMPLETE |

## Phase 3: Map Execution Flow

Build the pipeline representation:

```
┌─────────────────────────────────────┐
│ 1. REQUEST ANALYSIS                  │
│    - Intent parsed                    │
│    - Task classified                  │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│ 2. CONTEXT LOADING                   │
│    - Skills considered / loaded       │
│    - Files read                       │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│ 3. EXECUTION PATH                    │
│    - Tools invoked (with order)       │
│    - Delegation decisions             │
│    - Error recovery paths             │
└─────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────┐
│ 4. VALIDATION & COMPLETION           │
│    - Verification steps               │
│    - Final outcome                    │
└─────────────────────────────────────┘
```

For each step, document:
- **What happened** (tool calls, decisions)
- **Why** (rationale for choices)
- **How long** (if timing available)
- **Outcome** (success/failure/partial)

## Phase 4: Divergence Analysis

Identify where execution deviated from optimal:

| Indicator | What It Detects |
|-----------|----------------|
| **Context Skipping** | Did not read required files before acting |
| **Skill Bypass** | Used ad-hoc approach instead of a skill |
| **Wrong Delegation** | Dispatched to wrong agent type |
| **Tool Misuse** | Inefficient tool choice (bash vs dedicated tool) |
| **Validation Skip** | Completed without verifying |
| **Recovery Loops** | Same error repeated 3+ times without strategy change |
| **Premature Execution** | Started coding before understanding the problem |

## Phase 5: Present Flow Report

Display the execution pipeline with colour-coded stages:

```
🔴 REQUEST → 🟠 CONTEXT → 🟡 EXECUTION → 🟢 VALIDATION → ✅ COMPLETE
```

Mark each stage:
- ✅ Smooth (no issues)
- ⚠️ Minor detour (recovered quickly)
- ❌ Major divergence (wasted tokens/time)

**Tool statistics table**:
```
| Tool | Count | Success | Failed |
|------|-------|---------|--------|
| read | 12 | 12 | 0 |
| bash | 8 | 7 | 1 |
| edit | 5 | 5 | 0 |
```

**Execution Quality Verdict**: ✅ Smooth | ⚠️ Minor Issues | ❌ Major Errors

Present improvement options via question tool:
```
Flow analysis found N improvement opportunities:
- [ ] 1. {Issue} [Critical] — {recommendation}
- [ ] 2. {Issue} [Recommended] — {recommendation}
- [ ] Skip improvements
```

## Phase 6: Apply Improvements & Record

For approved improvements:
1. Apply fixes (update skills, context files, AGENTS.md rules)
2. Record trigger: `record_trigger.py flow --context "{session/task analysed}"`
3. Capture experience: `capture_conversation.py "Flow analysis: {summary}" --type experience --tags "flow,analysis"`
4. If skill improvements found, offer `improve {skill-name}` follow-up

## Anti-Patterns

| Pattern | Fix |
|---------|-----|
| Analysing without the full session | Always gather all data sources first |
| Only reporting errors | Flow = successes + failures + decisions |
| Skipping the improvement step | Every flow analysis should produce actionable recommendations |
| Vague recommendations | Each recommendation must be specific with file + line + fix |
| Not recording the analysis | Capture to memory so future sessions benefit |
