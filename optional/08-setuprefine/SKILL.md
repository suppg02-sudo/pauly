---
name: setuprefine
version: 1.0.0
description: Analyse recent work + existing repo instructions, propose improvements with recommendations
trigger: setuprefine, refine-setup, sr
maturity: L2
created: 2026-06-30
dependencies: []
tags: [meta, review, improvement, analysis]
---

# Setup Refine

## Overview

A meta-skill that **analyses the pauly repo** — recent work, issues found, and existing instructions — then **proposes specific improvements** via the question tool. The agent presents recommendations with clear reasoning; the user picks what to apply.

## Trigger Commands

- `setuprefine` — Full analysis + improvement proposals
- `refine-setup` — Alias
- `sr` — Short form

---

## Workflow (Agent MUST Follow Exactly)

```
1. COLLECT  — Gather data: git history, file inventory, issues
2. ANALYSE  — Review each file for gaps, inconsistencies, stale content
3. PROPOSE  — Generate improvement suggestions with recommendations
4. PRESENT  — Use question tool with grouped tabs of suggestions
5. APPLY    — User selects → agent implements → commit + push
6. VERIFY   — Confirm changes don't break anything
```

---

## Phase 1: COLLECT

The agent gathers:

### Recent Work
```bash
# Last 10 commits
git log --oneline -10

# Files changed in last 5 commits
git diff --stat HEAD~5 HEAD

# Current uncommitted changes
git status --short

# Any TODO/FIXME/HACK markers
grep -rn 'TODO\|FIXME\|HACK\|XXX' --include='*.md' --include='*.sh' --include='*.yml' --include='*.ts' --include='*.js' --include='*.astro' .
```

### Issues Detected
```bash
# .env.example vs actual .env drift (missing vars)
diff <(grep '=' .env.example | cut -d= -f1 | sort) <(grep '=' .env 2>/dev/null | cut -d= -f1 | sort) || true

# Ports referenced in compose files not in .env.example
grep -ohE '\$\{PORT_[A-Z_]+' directus/docker-compose.yml astro-docs/docker-compose.yml optional/*/docker-compose.yml 2>/dev/null | sort -u

# Skills referenced in AGENTS.md but not in skills/ directory
grep -ohE 'skills/[a-z-]+' AGENTS.md SETUP.md 2>/dev/null | sort -u

# docker-compose files referencing services not defined
for f in directus/docker-compose.yml astro-docs/docker-compose.yml; do
  echo "=== $f ==="
  grep -E '^\s+\w+:' "$f" | head -10
done

# Broken internal links in markdown
grep -rn '\[.*\](\./' --include='*.md' . | head -20
```

### File Inventory
```bash
# All markdown files
find . -name '*.md' -not -path './.git/*' | sort

# All scripts
find . -name '*.sh' -not -path './.git/*' | sort

# All compose files
find . -name 'docker-compose.yml' -not -path './.git/*' | sort

# All Dockerfiles
find . -name 'Dockerfile' -not -path './.git/*' | sort
```

---

## Phase 2: ANALYSE

The agent reads through key files and checks:

### Consistency Checks

| Check | What to Look For |
|-------|-----------------|
| **Port variables** | Every `${PORT_*}` in compose files has a matching entry in `.env.example` |
| **Credential vars** | Every `${*_PASSWORD}`, `${*_TOKEN}`, `${*_SECRET}` in compose has `.env.example` entry |
| **Skill references** | Every skill mentioned in AGENTS.md/SETUP.md exists in `skills/` or `optional/` |
| **Trigger commands** | Every trigger in AGENTS.md has a matching SKILL.md with that trigger |
| **Docker network** | All compose files reference the same `${DOCKER_NETWORK}` |
| **Init script coverage** | `init.sh` covers all phases mentioned in SETUP.md |
| **README accuracy** | Each README.md accurately describes its directory contents |
| **Cross-references** | SETUP.md phase numbers match actual file structure |
| **Stale defaults** | No `admin123`, `change-me`, `CHANGE_ME` in committed `.env.example` |

### Gap Checks

| Check | What to Look For |
|-------|-----------------|
| **Missing health checks** | Compose services without healthcheck blocks |
| **Missing logging config** | Services without `json-file` + `max-size` logging |
| **Missing memory limits** | Services without `deploy.resources.limits` |
| **Missing restart policy** | Services without `restart: unless-stopped` |
| **Hardcoded values** | Any port number, URL, or credential NOT wrapped in `${VAR}` |
| **Missing .env.example** | Any directory with docker-compose.yml but no .env.example |
| **Missing README** | Any `optional/` directory without a README.md |

### Recent Work Analysis

| Check | What to Look For |
|-------|-----------------|
| **Uncommitted work** | Files changed but not committed |
| **Recent issues** | Patterns in recent commits suggesting problems (fixes, reverts) |
| **Incomplete phases** | Optional directories started but not finished |
| **Orphaned files** | Files that don't belong to any phase |

---

## Phase 3: PROPOSE

Generate specific, actionable suggestions. Each suggestion MUST have:

| Field | Content |
|-------|---------|
| **Title** | Short name |
| **Category** | `consistency` / `security` / `completeness` / `DX` / `bug` |
| **Severity** | `critical` / `important` / `nice-to-have` |
| **What** | One sentence description |
| **Why** | Why it matters |
| **Where** | Specific file(s) affected |
| **Effort** | `trivial` / `quick` / `moderate` |

Present recommendations **sorted by severity** within each category.

---

## Phase 4: PRESENT (Question Tool — MANDATORY)

Present findings as **grouped tabs** using the question tool. Each tab is a category. User can select multiple items across tabs.

**The agent MUST:**
1. Lead each suggestion with `(Recommended)` if severity is critical or important
2. Include an "Apply all critical" option
3. Include an "Exit — apply nothing" option
4. Show the full list before asking to apply

### Example Menu Structure

```
Tab 1: Critical (must fix)
Tab 2: Important (should fix)
Tab 3: Nice-to-have (optional)
Tab 4: Apply / Exit
```

---

## Phase 5: APPLY

After user selects:

1. **Implement** each selected suggestion
2. **Show diff** of changes (`git diff`)
3. **Ask to commit** via question tool:
   - "Commit and push"
   - "Commit only (no push)"
   - "Show diff again"
   - "Discard changes"
4. **Write commit message** summarising what was refined

---

## Phase 6: VERIFY

After applying:

```bash
# Syntax check all YAML
python3 -c "import yaml,glob; [yaml.safe_load(open(f)) for f in glob.glob('**/*.yml', recursive=True)]; print('YAML OK')"

# Syntax check all shell scripts
find . -name '*.sh' -not -path './.git/*' -exec bash -n {} \; && echo "Shell OK"

# Check no hardcoded ports in compose files
grep -rn '8055\|8056\|3003\|4321' --include='docker-compose.yml' . | grep -v '\${' && echo "WARNING: hardcoded ports found" || echo "No hardcoded ports"

# Check .env.example has no default passwords
grep -i 'admin123\|change-me\|password123\|CHANGE_ME' .env.example && echo "WARNING: default credentials" || echo "Credentials OK"
```

---

## Menu Configuration

**Trigger**: `setuprefine`

```json
{
  "questions": [
    {
      "question": "Setup Refine — Analysis complete. Select improvements to apply:",
      "header": "Refine",
      "options": [
        { "label": "Run full analysis", "description": "Collect + analyse + propose (starts the workflow)" },
        { "label": "Quick check only", "description": "Just run consistency checks, no proposals" },
        { "label": "Review recent commits", "description": "Analyse last 10 commits for issues" },
        { "label": "Exit", "description": "Don't run analysis" }
      ],
      "multiple": false
    }
  ]
}
```

After analysis, present findings as multi-tab question tool menus (see Phase 4).

---

## Scripts

### `scripts/analyse.sh` — Quick consistency check

Runs the non-interactive checks and prints a report. Does NOT modify files.

```bash
bash optional/08-setuprefine/scripts/analyse.sh
```

---

Base directory: ~/.config/opencode/skills/setuprefine
