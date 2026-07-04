# session — Recover from session compaction or resume — diagnose incomplete items, fix, verify, report

> **Trigger**: `session` | **Purpose**: Recover from compacted/resumed sessions OR summarise + compact a live session
> **When to use**: After session compaction, when resuming work, when you receive a Goal/Instructions/Discoveries/Accomplished summary block, or when the user types `session` on a live session to summarise and compact
> **Live session shortcut**: If there is no compacted summary to recover (user just typed `session`), skip Phases 1-5 and go directly to Phase 6 (generate summary, ask about compaction).

## Phase 1: Read the Compacted State (🔴)

The session summary contains structured blocks. Parse them in order:

1. **Goal** — What we're building/changing. This is the target state.
2. **Instructions** — Constraints and rules for the work. Never violate these.
3. **Discoveries** — Facts learned during implementation (bash quirks, API gotchas, env issues). These prevent repeating mistakes.
4. **Accomplished** — What's done. Skip these. Contains `✅` (done), `⚠️` (in-progress/broken), and unmarked (not started).
5. **Relevant files** — Paths to modified files. These are your working set.

**Output**: A mental model of: target state, current state, delta.

## Phase 2: Diagnose Current State (🟠)

Run these checks on ALL files in the "Relevant files" list, prioritising anything marked `⚠️`:

```bash
# Syntax check every Python file
python3 -m py_compile <file.py>

# Syntax check every shell script
bash -n <file.sh>

# Check for common issues in modified files
grep -n "TODO\|FIXME\|HACK\|XXX\|BROKEN" <file>
```

**For each `⚠️` item**: Read the surrounding context (±30 lines from the reported line number) to understand the breakage before attempting a fix.

**Output**: Confirmed list of broken things with line numbers and root causes.

## Phase 3: Create Action Plan (🟡)

Build a todo list from the delta between "Accomplished" and "Goal":

1. `⚠️` items → **high priority** (partially done, needs fixing)
2. "Not yet done" items → **medium priority**
3. Verification/test items → **high priority** (must prove fixes work)

Use the `todowrite` tool. Mark items `in_progress` one at a time.

## Phase 4: Fix & Implement (🟢)

### Fixing Syntax Errors

1. Read the broken section with ±30 lines of context
2. Identify the root cause (mismatched try/except, indentation, missing import)
3. Edit with the **smallest possible change** — don't rewrite entire functions
4. Run `python3 -m py_compile` immediately after each edit
5. Only proceed to next fix after compile passes

### Fixing Runtime Issues

1. Reproduce the error with a minimal test
2. Check for env var loading (scripts often expect vars that aren't in scope)
3. Check for dependency issues (missing imports, changed APIs)
4. Fix and verify with a direct function call test

### Common Patterns Found in Compacted Sessions

| Pattern | Fix |
|---------|-----|
| `try:` wraps only 1 line, rest is orphaned | Move `try:` to wrap the entire logical block through to `except:` |
| `except` block without matching `try` | Check indentation — a misaligned `try:` may exist earlier, or the `try:` was added at the wrong point |
| Env vars not loaded from [`~/.env`](http://${SERVER_HOST}:8080/editor/storage${HOME}/.env) | Add dotenv loading at module top (read file, parse `KEY=VALUE`, set `os.environ`) |
| Bash `true`/`false` passed to Python | Use explicit string comparison or `"True"`/`"False"` variables |
| Function signature changed but callers not updated | Grep for all call sites, update arguments |
| Import added but module not installed | Check with `python3 -c "import <module>"` |
| npm workspace deps missing in Docker build | `cd packages/chat-ui && npm install` before app build in Dockerfile |

### npm Workspace Docker Rebuild Gotcha

**Discovery**: 2026-04-07 — `react-markdown` and other shared package dependencies silently missing from Docker bundles.

When rebuilding any app that consumes `packages/chat-ui/` (dashboard or chat-standalone):

1. **Shared package deps must install first**: The Dockerfile copies `packages/` into the build context but only runs `npm install` at the app level. The shared package's `node_modules/` never gets populated.
2. **Fix**: Add `RUN cd /workspace/packages/chat-ui && npm install --legacy-peer-deps` to the Dockerfile **before** the app-level `npm install`.
3. **Full rebuild after package.json changes**: `docker compose build --no-cache dashboard chat-standalone && docker compose up -d`
4. **Disk space**: Docker build cache fills disk fast. Run `docker image prune -a -f` before rebuilds if `/` is > 90% full.
5. **Symptom**: App compiles without TypeScript errors but missing modules at runtime (e.g., `react-markdown` not in bundle). Console shows no errors — the import just silently fails.

## Phase 5: Verification (🔵)

After all fixes compile and unit tests pass:

1. **Run whatever test/lint/build commands** are appropriate for the project
2. **Verify fixes work** by running the affected code paths directly
3. **Check env vars** are loaded if the code depends on them
4. **Cleanup** any test artifacts created during verification

## Phase 6: Report, Summarise & Compact (🟣)

After all verification passes:

1. **Generate a session summary** with these structured blocks:
   - **Goal** — What was being built/changed (the target state)
   - **Instructions** — Constraints and rules that must carry forward. Never violate these.
   - **Discoveries** — Facts learned during implementation (bash quirks, API gotchas, env issues). These prevent repeating mistakes.
   - **Accomplished** — What's done. Use `✅` (done), `⚠️` (in-progress/broken), and unmarked (not started).
   - **Relevant files / directories** — Paths to modified files. These are the working set.
2. **Present the summary** to the user for review
3. **Ask the user** — "Would you like to compact the context window now?" Use the question tool with options: Compact now, Skip (just continue)
4. **If user chose Compact now**: Instruct the user to type `/compact` in their TUI (cannot be triggered programmatically). The summary becomes the seed for the next session — the user can paste it in or type `session` after compaction to have it parsed by this protocol.
5. **Capture discoveries** — Any new gotchas found during this session
6. **Record the trigger usage**:
   ```bash
   python3 ~/.config/opencode/scripts/record_trigger.py session --context "<what was recovered>"
   ```

## Flow Visual

🔴 `Read State` → 🟠 `Diagnose` → 🟡 `Plan` → 🟢 `Fix` → 🔵 `Verify` → 🟣 `Report` → ✅ `Done`

## Quick Reference — Checks to Always Run

| Check | Command | When |
|-------|---------|------|
| Python syntax | `python3 -m py_compile <file>` | After every edit |
| Shell syntax | `bash -n <file>` | After every edit |
| Env vars loaded | `python3 -c "from <module> import VAR; print(VAR)"` | After adding env-dependent code |
| Service reachable | `curl -s -o /dev/null -w "%{http_code}" <url>` | Before API calls |
| Container running | `docker ps --filter name=<name>` | Before Docker-dependent ops |

## ⚠️ Anti-Patterns — Things That Waste Tokens

### `/compact` CANNOT Be Triggered Programmatically

**Discovery**: 2026-04-07 — multiple failed attempts across CLI, API, and plugin hooks all confirmed `/compact` is TUI-only.

| Method | Works? | Why |
|--------|--------|-----|
| `opencode compact` via Bash | ❌ | TUI interactive output, times out |
| `POST /project/:id/session/:id/compact` | ❌ | Internal API, not externally accessible |
| oh-my-opencode hooks (`pre-compact`, `auto-slash-command`) | ❌ | Plugin runtime, not agent runtime |
| Agent bash `opencode compact` | ❌ | Produces TUI escape codes that never complete |

**Correct approach**: Present summary → ask if user wants to compact → if yes, tell them to type `/compact` in their TUI.
