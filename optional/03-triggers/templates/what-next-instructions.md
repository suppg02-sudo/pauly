# ? — Analyse current state, surface priorities, recommend next steps

> **Trigger**: `?` or `what next` | **Purpose**: Analyse current state, surface priorities, recommend next steps
> **Context file**: [this file](http://${SERVER_HOST}:8080/editor/opencode/agents/context/what-next-instructions.md)
> **Template**: [trigger-protocol-template.md](http://${SERVER_HOST}:8080/editor/opencode/agents/context/trigger-protocol-template.md)
> **When to use**: Between tasks, at session start, or when unsure what to work on

## Phase 0: Clarifying Questions

Ask via question tool. Skip if user provides context (e.g., `? ProjectX` or `? blog`).

**Question 1**: "What horizon are you thinking about?"

| Option | Scope | Why |
|--------|-------|-----|
| **Right now** (Recommended) | Next 1-2 hours, immediate priorities | Quick wins and blockers |
| **Today** | This session's work plan | Balanced view of what's doable |
| **This week** | Short-term priorities and planning | Strategic, cross-session |

**Question 2**: "What kind of recommendation do you want?"

| Option | Output |
|--------|--------|
| **Single best next step** (Recommended) | One action with rationale — just tell me what to do |
| **Ranked list** | Top 5 options with effort estimates and priority tags |
| **Full analysis** | Complete scan of all domains with status per area |

## Phase 1: Read State

Gather current state from these sources (in order):

1. **Read** [`current_state.md`](http://${SERVER_HOST}:8080/editor/opencode/current_state.md) — recently completed, active topics
2. **Run** `deferred list 2>/dev/null` — parked items waiting to surface
3. **Run** `python3 ~/.config/opencode/scripts/hybrid_tracker.py flow list --active 2>/dev/null` — in-progress flows
4. **Run** `pghmem search "decision" --recent 7d 2>/dev/null` — recent decisions
5. **Run** `python3 ~/.config/opencode/skills/ideas/scripts/idea.py surface --auto 2>/dev/null` — surfaced ideas
6. **Check** `wiki_inbox_list` — pending wiki items needing approval
7. **Check** active GitHub issues if relevant: `gh issue list --limit 5`

## Phase 2: Analyse

Process gathered state into categories:

| Category | What to Look For |
|----------|-----------------|
| **Blockers** | Broken services, failed builds, unresolved errors |
| **In-progress** | Partially completed tasks, open PRs, unfinished flows |
| **Deferred surfacing** | Parked items whose priority may have increased |
| **Quick wins** | Small tasks (<30 min) that close loops |
| **Revenue opportunities** | Anything monetisable — blog posts, products, consultancy |
| **Maintenance** | Updates, cleanup, health checks that prevent future issues |
| **Fresh ideas** | Recently surfaced ideas worth exploring |

For each item, assign:
- **Priority**: Critical / Recommended / Nice-to-have
- **Effort**: Low (<30 min) / Medium (1-3 hr) / High (3+ hr)
- **Domain**: Which area it touches (blog, infra, skills, research, etc.)

## Phase 3: Present Options

### For "Single best next step":
Present one recommendation with reasoning:

```
Recommended: {action} [{Priority}]
Reasoning: {why this over others}
Effort: {Low/Medium/High}
Prerequisite: {any dependency}
```

Ask: "Go ahead with this? Or see the full ranked list?"

### For "Ranked list":
Present top 5 via question tool (multi-select if user wants to queue several):

```
- [ ] 1. {Name} [Critical] — {effort} — {description}
- [ ] 2. {Name} [Recommended] — {effort} — {description}
...
```

### For "Full analysis":
Present a status table per domain, then top 3 recommendations:

```
| Domain | Status | Key Items |
|--------|--------|-----------|
| Blog | 2 drafts pending | Post X needs date_published |
| Infra | Healthy | All services up |
| Skills | 3 improvements queued | menu-factory signal tracking |
...

Top 3 Recommendations:
1. ...
2. ...
3. ...
```

## Phase 4: Execute (if selected)

If user picks an action, either:
1. Start executing it directly
2. Load the relevant skill first (e.g., `astro` for blog work, `monitor` for infra)
3. Defer remaining items: `deferred add "{name}" --desc "{context}"`

## Phase 5: Confirm & Record

1. Record trigger: `record_trigger.py ? --context "{what was recommended/selected}"`
2. If items were deferred from the list: note them in `deferred_options.json`

## Anti-Patterns

| Pattern | Fix |
|---------|-----|
| Listing everything without prioritising | Every item gets Priority + Effort tags |
| Ignoring deferred items | Always check `deferred list` — they surface for a reason |
| Skipping revenue evaluation | Flag monetisable opportunities explicitly |
| Not checking active flows | `hybrid_tracker.py flow list --active` shows what's mid-flight |
| Recommending without effort estimates | Always tag Low/Medium/High effort |
| Offering "Exit" or "Disk cleanup" as options | Signal data: 4x shown, 0 picks each. Exit is implicit, disk cleanup = `space` trigger |
