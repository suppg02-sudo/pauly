# co — Resume or continue the most recent/current task with full context recovery

> **Trigger**: `co` | **Purpose**: Resume or continue the most recent/current task with full context recovery
> **Context file**: [this file](http://${SERVER_HOST}:8080/editor/opencode/agents/context/continue-instructions.md)
> **Template**: [trigger-protocol-template.md](http://${SERVER_HOST}:8080/editor/opencode/agents/context/trigger-protocol-template.md)
> **When to use**: After a pause, interruption, session compaction, or when switching back to an earlier task

## Phase 0: Context Recovery

Before asking the user anything, gather state silently:

1. **Read** [`current_state.md`](http://${SERVER_HOST}:8080/editor/opencode/current_state.md) — what was recently worked on
2. **Check** if there are active todos in the current session (in-memory)
3. **Run** `python3 ~/.config/opencode/scripts/hybrid_tracker.py flow list --active 2>/dev/null` — in-progress flows
4. **Run** `deferred list 2>/dev/null` — recently deferred items
5. **Check** session conversation — look for the last incomplete task, open question, or pending action

## Phase 1: Identify What to Continue

Based on gathered state, classify what's resumable:

| Signal | Meaning | Action |
|--------|---------|--------|
| Active todos in session | Task was started but not finished | Resume the in_progress item |
| Last action was a question tool call | User was presented options but didn't answer | Re-present the same options |
| Last action was a `deferred add` | Task was explicitly parked | Ask if now is the time |
| `current_state.md` shows recent work | Task may be done or needs follow-up | Check if verification is needed |
| Active flows in tracker | Multi-step flow in progress | Resume at the current step |
| Session has no clear task | Nothing obvious to continue | Fall through to Phase 2 |

## Phase 2: Clarifying Questions

Only ask if Phase 1 is ambiguous or multiple things are resumable.

**If single clear task found**: Confirm it directly:

```
Last task: {description} ({status})
Resume this? [Yes / See alternatives / Something else]
```

**If multiple candidates**: Present via question tool:

```
Multiple tasks could be continued — which one?
- [ ] 1. {Task A} [Recommended] — {status}, {effort remaining}
- [ ] 2. {Task B} — {status}, {effort remaining}
- [ ] 3. Start something new (use ? for recommendations)
```

**If nothing found**: Offer `?` (what next) instead — no point continuing nothing.

## Phase 3: Reload Context

Once the task is identified, reload the necessary context:

1. **Re-read** any files that were being edited
2. **Re-read** any skill that was loaded (use `skill` tool)
3. **Re-create** the todo list if it was lost
4. **Summarise** where we left off in 1-2 sentences

**Context reload format**:
```
Resuming: {task name}
Where we left off: {last action/status}
Next step: {what to do now}
```

## Phase 4: Execute

Continue the task from where it was left off. Do NOT restart from scratch.

Key rules:
- If a file was being edited, read it first to see current state
- If a skill was loaded, load it again
- If tests were being run, run them to see current status
- If a PR was in progress, check its current state

## Phase 5: Confirm & Record

1. Record trigger: `record_trigger.py co --context "{what was resumed}"`
2. Update `current_state.md` if the task is now complete

## Anti-Patterns

| Pattern | Fix |
|---------|-----|
| Restarting a task from scratch | Always check where it was left off first |
| Asking "what were you working on?" | Gather state silently first, then confirm |
| Loading too much context | Only reload what's needed for the specific task |
| Not checking active flows | `hybrid_tracker.py` shows mid-flight work |
| Continuing a completed task | Verify it's actually incomplete before resuming |
