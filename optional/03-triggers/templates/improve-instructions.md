# improve — Analyse and improve ANY system component — skills, prompts, menus, config, triggers, docs, workflows

> **Trigger**: `improve` | **Purpose**: Analyse and improve ANY system component — skills, prompts, menus, config, triggers, docs, workflows
> **Context file**: [this file](http://${SERVER_HOST}:8080/editor/opencode/agents/context/improve-instructions.md)
> **Template**: [trigger-protocol-template.md](http://${SERVER_HOST}:8080/editor/opencode/agents/context/trigger-protocol-template.md)
> **When to use**: When something could be better — not just skills, anything improvable

## Phase 0: Clarifying Questions

Ask via question tool. Skip if user provides a target (e.g., `improve menu-factory` or `improve AGENTS.md`).

**Question 1**: "What do you want to improve?"

| Option | Scope | Examples |
|--------|-------|----------|
| **A specific skill** (Recommended) | Single skill improvement | `improve pa`, `improve astro` |
| **A config/context file** | AGENTS.md, trigger-words, environment files | `improve AGENTS.md` |
| **A menu or prompt** | Menu options, prompt templates | `improve menu-factory menus` |
| **A workflow/pipeline** | Multi-step processes | `improve blog pipeline` |
| **Auto-detect from session** | Scan session for improvement opportunities | Finds patterns automatically |

**Question 2** (only if not auto-detect): "What aspect?"

| Option | Focus |
|--------|-------|
| **Structure & clarity** | Reorganise, simplify, progressive disclosure |
| **Completeness** | Missing instructions, gaps, undocumented features |
| **Token efficiency** | Reduce bloat, compress, move to L1/L2 |
| **Error prevention** | Anti-patterns, gotchas, safety rules |
| **Full review** (Recommended) | All of the above |

## Phase 1: Read Target

Based on scope:

| Target Type | What to Read |
|-------------|--------------|
| Skill | `SKILL.md`, `skill.yaml`, scripts directory, recent usage logs |
| Config file | The file itself + files that reference it |
| Menu | Menu SKILL.md + `signal.py stats` + `menu_violations.jsonl` |
| Prompt | Prompt file + `promptlib stats` |
| Workflow | All steps in the pipeline + recent execution logs |
| Auto-detect | Current session + `skill-improver` analysis |

## Phase 2: Analyse

For each target, evaluate across these dimensions:

| Dimension | What to Check |
|-----------|---------------|
| **Accuracy** | Does it reflect current state? Any stale references? |
| **Completeness** | Are there undocumented features or missing instructions? |
| **Structure** | Does it follow progressive disclosure (L0/L1/L2)? |
| **Consistency** | Does it match patterns used by similar components? |
| **Token cost** | Is anything in L0 that should be L1/L2? |
| **Error prevention** | Are common mistakes addressed? Gotchas documented? |
| **Usability** | Can a small model (7B-14B) follow it correctly? |

## Phase 3: Prioritise Improvements

Classify each finding:

| Tag | When to Use |
|-----|-------------|
| **Critical** | Broken instructions, missing safety rules, incorrect paths |
| **Recommended** | Token savings, better structure, missing anti-patterns |
| **Nice-to-have** | Style improvements, better examples, clearer wording |
| **Deferred** | Nice but not worth the token cost to change |

## Phase 4: Present Options

Present via question tool with multi-select:

```
Found N improvements for {target}:
- [ ] 1. {Name} [Critical] — {dimension}: {description}
- [ ] 2. {Name} [Recommended] — {dimension}: {description}
...
```

Group by dimension if >6 items.

## Phase 5: Apply

For each approved improvement:
1. Read the target file
2. Apply smallest possible edit
3. Verify syntax/format
4. If it's a skill, run any validation: `python3 scripts/validate_*.py`

## Phase 6: Confirm & Record

1. Summarise what was improved
2. Record trigger: `record_trigger.py improve --context "{what was improved}"`
3. Capture experience: `capture_conversation.py "Improved {target}" --type experience --tags "improve,{target_type}"`
4. Signal skill event if skill was improved: `skill_event.py --skill {name} --event complete`

## Skill-Specific Bridge

When target is a skill, this protocol bridges to the full `skill-improver` SKILL.md which has deeper analysis (usage logs, failure patterns, cross-file consistency). Load it if deeper analysis is needed:

```
skill skill-improver
```

## Anti-Patterns

| Pattern | Fix |
|---------|-----|
| Only improving skills | `improve` is generic — works on any system component |
| Making everything L0 | Push detail to L1/L2 to save tokens |
| Rewriting entire files | Smallest possible edit — ±20 lines max |
| Not checking consistency | Compare against similar components for patterns |
| Skipping the 7B test | If a small model can't follow it, simplify |
