# Setup Refine

## What This Provides

A meta-skill that analyses the pauly repo for issues, inconsistencies, and improvement opportunities — then proposes fixes via the question tool with recommendations.

## Trigger Commands

| Trigger | Action |
|---------|--------|
| `setuprefine` | Full analysis: collect → analyse → propose → apply |
| `refine-setup` | Alias |
| `sr` | Short form |

## What It Checks

| Category | Checks |
|----------|--------|
| **Port variables** | Every `${PORT_*}` in compose files exists in `.env.example` |
| **Credential variables** | Every `${*_PASSWORD/TOKEN/SECRET}` exists in `.env.example` |
| **Default passwords** | No `admin123`, `change-me`, `CHANGE_ME` in `.env.example` |
| **Hardcoded ports** | No literal port numbers in compose files (must use `${VAR}`) |
| **Health checks** | Every compose service has a healthcheck block |
| **Logging config** | Every service has `json-file` + `max-size` logging |
| **Missing READMEs** | Every `optional/` dir has a README.md |
| **Missing SKILL.md** | Every `skills/` dir has a SKILL.md |
| **Trigger coverage** | Every trigger in AGENTS.md has a matching SKILL.md |
| **TODO/FIXME** | No outstanding markers in committed files |
| **Git status** | Clean working tree |

## Usage

```bash
# Quick non-interactive check
bash optional/08-setuprefine/scripts/analyse.sh

# Full interactive analysis (via OpenCode skill)
# Trigger: setuprefine
```

## Install as Skill

```bash
cp -r /opt/pauly/optional/08-setuprefine ~/.config/opencode/skills/setuprefine
```

## Workflow

```
1. COLLECT  — git log, file inventory, grep for issues
2. ANALYSE  — read key files, check consistency + gaps
3. PROPOSE  — generate suggestions (severity-ranked)
4. PRESENT  — question tool with grouped tabs
5. APPLY    — implement selected → diff → commit
6. VERIFY   — YAML lint, shell lint, port check
```
