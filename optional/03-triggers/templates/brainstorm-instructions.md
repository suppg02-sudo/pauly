# bs — Creative exploration and ideation — Quick Think or structured design sessions

> **Trigger**: `bs` or `brainstorm` | **Purpose**: Creative exploration and ideation — Quick Think or structured design sessions
> **Context file**: [this file](http://${SERVER_HOST}:8080/editor/opencode/agents/context/brainstorm-instructions.md)
> **Context Manifest**: [`openspec-context-manifest.md`](http://${SERVER_HOST}:8080/editor/opencode/agents/context/openspec-context-manifest.md) — shared context source definitions
> **Template**: [trigger-protocol-template.md](http://${SERVER_HOST}:8080/editor/opencode/agents/context/trigger-protocol-template.md)
> **When to use**: Before creative work, feature design, architecture decisions, or when exploring ambiguous problems

## Trigger Detection & Routing

The trigger format determines the entry point:

| Trigger Format | Topic | Flow |
|----------------|-------|------|
| `bs <topic>` or `brainstorm <topic>` | Provided | Phase 0.5 → Phase 1 (skip clarifying questions) |
| `bs` or `brainstorm` (bare) | Missing | Phase 0.5 → Phase 0 → Phase 1 (ask after context) |

**When topic is provided with the trigger** (e.g., `bs landing page design`, `brainstorm monetisation`):
- Default mode: **Quick Think** (can be overridden by user in Phase 0.5)
- Default schema consideration: **No** (can be overridden by user in Phase 0.5)

## Phase 0.5: Context Injection (Multi-Select) — ALWAYS RUN FIRST

**This is the first thing that runs** — always, regardless of whether topic was provided.

Gather live metadata:

```bash
python3 ~/.config/opencode/scripts/system_identity.py --level L1 2>/dev/null || echo "identity-unavailable"
head -40 ~/.config/opencode/current_state.md
head -20 ~/.config/opencode/schemas/schema-registry.yaml
grep -c "word:" ~/.config/opencode/triggers.yaml
```

Enable multi-select and present the context menu via question tool (`multiple: true`):

```bash
python3 ~/.config/opencode/skills/menu-factory/scripts/menu_mode.py --multi-select on
```

Present this question:

> **"Select context to inject into the brainstorm about `{topic}`:"**

(or "Select context for brainstorm session:" if bare trigger)

**Options:**

| Label | Description | What Gets Injected |
|-------|-------------|-------------------|
| 🏛️ Telos | Mission, principles, Triad | Summary of telos.md — mission, core desires, Triad schema |
| 🌐 Environment | Services, ports, Docker topology | Service table from environment-awareness.md |
| 📐 Schemas | Schema registry + manifest | Schema names, health scores, consumers, dependency edges |
| 🧬 Factories | Factory pipelines and contracts | Factory names, input schemas, output types |
| 🔄 Evolve | Evolution engine state | Active domains, signal loop status, pending improvements |
| 📍 Current State | Active topics + recent work | Active topics table + last 5 completed items |
| ⚡ Triggers | Trigger registry summary | Trigger count, categories, most relevant triggers |
| 🧠 Memory | Relevant past decisions | `pghmem search "<topic>"` results |
| 🎯 All Context | Everything above | Full snapshot of all sources |
| ⚡ None (Recommended) | Skip context, just brainstorm | No context injection |

**Recommendation logic:**
- Quick Think (default when topic provided) → recommend "None" (speed over context)
- Feature design → recommend "Environment + Schemas"
- Architecture → recommend "All Context"
- Problem solving → recommend "Current State + Memory"
- Content ideas → recommend "Current State + Memory"

**Also include in the same multi-select menu** (if topic was provided with trigger, let user override mode):

| Label | Description |
|-------|-------------|
| 🔄 Switch to Structured | Change from Quick Think to full structured session |
| 🔄 Switch to Architecture | Change to architecture-focused session |

These mode overrides are only shown when topic was provided with trigger.

**Injection for each selected source** (compact summaries, under 200 tokens each):

- **Telos**: `head -100 ~/.config/opencode/docs/instructions/telos.md` → extract mission + Triad
- **Environment**: Extract service table from `agents/context/environment-awareness.md` (L0 only)
- **Schemas**: `head -20 ~/.config/opencode/schemas/schema-registry.yaml` → schema count + health
- **Factories**: Extract factory names + actions from agent DNA in `agents/brainstorm.md`
- **Evolve**: `head -50 ~/.config/opencode/skills/evolve/SKILL.md` → domain list
- **Current State**: `head -40 ~/.config/opencode/current_state.md` → active topics table
- **Triggers**: `grep "word:" ~/.config/opencode/triggers.yaml | wc -l` → count + relevant ones
- **Memory**: `pghmem search "<topic>" --limit 5` → results

**After selection**, reset multi-select and record signals:

```bash
python3 ~/.config/opencode/skills/menu-factory/scripts/menu_mode.py --multi-select off
python3 ~/.config/opencode/skills/menu-factory/scripts/signal.py both --skill brainstorm --present-options '["🏛️ Telos","🌐 Environment","📐 Schemas","🧬 Factories","🔄 Evolve","📍 Current State","⚡ Triggers","🧠 Memory","🎯 All Context","⚡ None"]' --select-option '<selected>' --select-position <n>
```

## Phase 0: Clarifying Questions (only if bare trigger, no topic)

**This phase only runs when no topic was provided** (bare `bs` or `brainstorm`). It runs AFTER Phase 0.5 context selection so the agent can use injected context to ask better clarifying questions.

Ask via question tool.

**Question 1**: "What are we brainstorming?"

| Option | Scope |
|--------|-------|
| **Quick Think** (Recommended) | 5 ideas in 2 minutes — fast ideation on current topic |
| **Feature design** | Structured design session for a specific feature |
| **Architecture** | System design, component relationships, data flows |
| **Problem solving** | Debugging approach, root cause exploration |
| **Content ideas** | Blog topics, product names, marketing angles |

**Question 2**: "Should we consider the overall schema structure, factories, and control plane?"

| Option | When |
|--------|------|
| **Yes** (Recommended for architecture) | Include schema-registry, factory patterns, system topology in the brainstorm |
| **No** | Focus purely on the topic without system-level thinking |

**Pass injected context from Phase 0.5** to the chosen route handler in Phase 1.

## Phase 1: Route

Based on the answer, route to the correct handler:

| Route | Handler | When |
|-------|---------|------|
| **Quick Think** | Handle locally — agent does fast ideation in-context | User just needs quick ideas, no delegation needed |
| **Structured design** | Delegate to @brainstorm agent via Task tool | Deep design session with full research capabilities |
| **Architecture** | Delegate to @brainstorm agent + include schema context | System-level design decisions |
| **Problem solving** | Load `systematic-debugging` skill first, then brainstorm | Debugging + creative solution exploration |
| **Content ideas** | Handle locally or delegate based on depth | Blog/product ideation |

When delegating to @brainstorm agent, include the injected context block in the prompt:

```
Task tool:
  subagent_type: brainstorm
  prompt: "Brainstorm session on {topic}.
           Schema consideration: {yes/no}.
           Injected context:
           {selected context summaries, each under 200 tokens}
           Return: ideas with feasibility, effort, and recommendation."
```

## Phase 2: Execute — Quick Think (Local)

For Quick Think mode (handled locally, no agent delegation):

1. **State the topic** clearly in 1 sentence
2. **Generate 5 ideas** — numbered, 1-2 lines each, creative and varied
3. **Tag each idea**: Feasibility (High/Medium/Low) + Effort (Low/Medium/High)
4. **Recommend** the best one with reasoning

Format:
```
Topic: {topic}

1. {Idea} — Feasibility: H | Effort: L
2. {Idea} — Feasibility: M | Effort: M
3. {Idea} — Feasibility: H | Effort: H
4. {Idea} — Feasibility: L | Effort: L
5. {Idea} — Feasibility: M | Effort: M

Recommended: #{n} — {why}
```

## Phase 3: Execute — Structured (Delegated)

For structured sessions, delegate to @brainstorm agent:

```
Task tool:
  subagent_type: brainstorm
  prompt: "Brainstorm session on {topic}.
           Schema consideration: {yes/no}.
           Context: {brief summary of current state}.
           Injected context: {selected context block}.
           Return: ideas with feasibility, effort, and recommendation."
```

**Rules for delegation**:
- Always pass the topic and schema consideration answer
- Include injected context from Phase 0.5
- Include relevant context (what led to this brainstorm)
- The @brainstorm agent uses `anthropic/claude-opus-4-6` for deeper reasoning
- Record the delegation: `subagent_wrapper.py brainstorm success --context "{topic}"`

## Phase 4: Follow-Up

After brainstorm completes:

1. **If user picks an idea**: Offer next steps (create skill, write plan, start implementation)
2. **If user wants more**: Re-run with a different angle or constraint
3. **Capture promising ideas**: `python3 ~/.config/opencode/skills/ideas/scripts/idea.py add --title "{idea}" --tags "brainstorm,{topic}"`

## Phase 5: Record

1. Record trigger: `record_trigger.py bs --context "{topic} — {N ideas generated}"`
2. Record subagent: `subagent_wrapper.py brainstorm success --context "{topic}"`

## Anti-Patterns

| Pattern | Fix |
|---------|-----|
| Delegating Quick Think | Quick Think is fast local ideation — no agent needed |
| Not asking about schema | Always ask if system-level thinking is relevant |
| Forgetting to capture ideas | Good ideas get lost — save to ideas system |
| Brainstorming before understanding the problem | State the problem clearly first |
| Only generating safe ideas | Push for at least 1 unconventional idea per session |
| Injecting too much context for Quick Think | Quick Think should be fast — context slows it down |
