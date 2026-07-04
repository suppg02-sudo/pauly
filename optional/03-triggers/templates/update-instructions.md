# u — Review session work, propose skill/context updates with per-item approval

> **Trigger**: `u` or `update` | **Purpose**: Review session work, propose skill/context updates, get user approval per item
> **Context file**: [this file](http://${SERVER_HOST}:8080/editor/opencode/agents/context/update-instructions.md)
> **Template**: [trigger-protocol-template.md](http://${SERVER_HOST}:8080/editor/opencode/agents/context/trigger-protocol-template.md)
> **When to use**: After completing work, or when the user explicitly types `u` or `update`

## Phase 0: Gather Context & Establish Scope

### Step 1: Silent Reconnaissance (no user interaction)

Gather recent context to build an intelligent picture of what may need updating:

1. **Read** [`current_state.md`](http://${SERVER_HOST}:8080/editor/opencode/current_state.md) — what was recently completed, active topics
2. **Scan** the current session conversation — what was worked on, what changed
3. **Run** `pghmem search "decision" --recent 7d` — recent decisions that may need documenting
4. **Run** `python3 ~/.config/opencode/scripts/hybrid_tracker.py flow list --active 2>/dev/null` — in-progress flows
5. **Check** what skills were loaded this session (from session history)
6. **Check** what files were edited this session (from session history)
7. **Check** for any new services, ports, containers, or config changes

### Step 2: Build Update Map

From the gathered context, categorise what might need updating:

| Category | What to Check | Signals |
|----------|---------------|---------|
| **Skills** | Skills loaded/used this session | Were there errors? Missing instructions? Gotchas discovered? |
| **GA (AGENTS.md)** | Always-on rules | New services? Changed ports? New anti-patterns? Deprecated items? |
| **Triggers** | Trigger registry | New behaviours? Missing aliases? Stale descriptions? |
| **Context files** | Files in `agents/context/` | Outdated references? Missing protocols? |
| **Environment** | Services, containers, ports | Anything deployed/changed/removed this session? |
| **Menus** | Menu configs | New options? Signal data suggesting reordering? |
| **Schemas** | Schema registry | New schemas? Changed fields? Missing consumers? |
| **Memory** | Decisions, patterns, lessons | Unrecorded decisions? Lessons from this session? |
| **Wiki** | Wiki inbox/pages | Pending items? Stale pages? |

### Step 3: Present Intelligent Suggestions

Use the question tool to present what was found, with recommendations:

```
Based on this session, here's what may need updating:

- [ ] 1. {Skill Name} — {what was found} (Recommended)
- [ ] 2. AGENTS.md — {what was found}
- [ ] 3. {Trigger/context} — {what was found}
- [ ] 4. Full audit (scan everything)
- [ ] 5. Skip — nothing to update
```

**Rules**:
- Pre-select items with clear signals (skills that had issues, services that changed)
- Mark Recommended for high-impact items
- Group by category if >6 items
- Include "Full audit" and "Skip" as always-present options
- If user provides a specific target (e.g., `u astro`), skip this and go direct

## Phase 1: Read Current State

Based on the scoped answers:

1. **Read** [`current_state.md`](http://${SERVER_HOST}:8080/editor/opencode/current_state.md) — what was recently completed
2. **Read** [`AGENTS.md`](http://${SERVER_HOST}:8080/editor/opencode/AGENTS.md) — current always-on context
3. **List** [`skills/`](http://${SERVER_HOST}:8080/editor/opencode/skills/) — installed skills
4. **Read** [`trigger-words.md`](http://${SERVER_HOST}:8080/editor/opencode/agents/context/trigger-words.md) — current trigger registry
5. If specific target: read that file directly, skip the broad scan

## Phase 2: Session Review

Analyse the conversation history (or broader scope) for:

1. **Missing instructions** — things the agent should know but doesn't (gotchas, patterns, rules)
2. **Progressive disclosure additions** — new L1/L2 sections for features that deserve layered docs
3. **Deprecated content** — old methods still listed as active but superseded
4. **Anti-patterns** — wasted token patterns discovered during the session
5. **New services/components** — deployed things not yet documented
6. **Common patterns** — reusable solutions that should be in the recovery protocol
7. **Disabled/no-op items** — things intentionally turned off that future agents might try to "fix"
8. **Environment changes** — new ports, services, containers, config files

## Phase 3: Cross-Reference

For each finding, determine:

| Target Type | Where to Put It |
|-------------|-----------------|
| Always-on rules, anti-patterns, quick refs | `AGENTS.md` or `session-recovery.md` |
| Feature-specific knowledge | Relevant skill's `SKILL.md` (L0/L1/L2) |
| Trigger/shortcut info | `trigger-words.md` |
| Environment/service inventory | `environment-tracking.md` |
| Pipeline/flow documentation | Context file in `agents/context/` |
| Visual patterns, design systems | `visual-companion/SKILL.md` |
| Schema/decision knowledge | Wiki via `wiki_submit` |

## Phase 4: Compile Proposals

For each finding, create a proposal with:

- **Proposal name**: Short label (e.g., "NextExplorer rw mount")
- **Target file**: Which file to update
- **Progressive disclosure level**: L0 (always loaded), L1 (medium), L2 (detailed), or new L2 subsection
- **Change type**: New section, deprecation notice, anti-pattern, table update, example code
- **Reason**: What prompted this (specific session event or discovery)
- **Proposed content**: The exact markdown/code to add

**Priority classification** — tag each proposal:

| Tag | Meaning | When to use |
|-----|---------|-------------|
| **Critical** | Prevents errors or data loss in future sessions | Wrong port, missing auth, broken pipeline |
| **Recommended** | Saves tokens or prevents common mistakes | Anti-pattern, better instruction, missing rule |
| **Nice-to-have** | Improves clarity or completeness | Better docs, progressive disclosure addition |
| **Deferred** | Useful but not urgent | Low-impact improvement |

## Phase 5: Present as Q&A

Present ALL proposals in a single question tool call with multi-select enabled:

```
Found N proposals — select the ones you want applied:
- [ ] 1. Name [Critical/Recommended/Nice-to-have] — description → target file
- [ ] 2. Name [Recommended] — description → target file
...
```

**Label format**: `{number}. {Name} [{Priority}]` — max 2-3 words for name
**Description format**: What changes + target file + level in concise form

**Recommendation rules**:
- Auto-select Critical items (pre-select them)
- Mark Recommended items with (Recommended) in description
- Group by target file so the user sees related changes together
- If >8 proposals, batch into "High priority" and "Lower priority" groups

## Phase 6: Apply Approved Updates

For each approved proposal:
1. Read the target file
2. Apply the smallest possible edit
3. Verify syntax/format after edit
4. Record the change

## Phase 7: Confirm & Record

1. List what was applied (with file paths)
2. List what was declined (offer `deferred add` for each)
3. Capture experience: `capture_conversation.py "Updated N items via u trigger" --type experience --tags "update,skills"`
4. Record trigger: `record_trigger.py u --context "{summary}"`

## Anti-Patterns

| Pattern | Why Bad | Fix |
|--------|---------|-----|
| Applying all proposals without asking | User wants control over their config | Always present as multi-select question |
| Putting skill-specific info in AGENTS.md | L0 bloat — every session pays the token cost | Use skill SKILL.md or context files |
| Not using progressive disclosure info | Updates go into wrong level | Classify each change: L0=always-on, L1=medium, L2=reference |
| Rewriting large sections | High risk of breaking existing content | Smallest possible edit, ±20 lines of context |
| Not recording trigger | No tracking of update activity | Always `record_trigger.py u` after |
| Skipping clarifying questions | Wastes time scanning irrelevant scope | Always ask scope and type preferences first |
| Proposing without priority | User can't triage quickly | Tag every proposal Critical/Recommended/Nice-to-have |
| Not offering deferred capture | Good ideas get lost | Offer `deferred add` for declined proposals |
