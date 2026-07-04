## menu — Present the central menu hub — all available options, skills, and tools in one place

### Overview

All skills reference a **central menu configuration** for mandatory options. This ensures consistency across all skill menus and provides a single source of truth for navigation options.

### Source of Truth

**Menu rules**: [`~/.config/opencode/triggers.yaml`](http://${SERVER_HOST}:8080/editor/opencode/triggers.yaml) → `menu_rules` section
**Trigger registry**: [`~/.config/opencode/triggers.yaml`](http://${SERVER_HOST}:8080/editor/opencode/triggers.yaml)
**Machine-readable options**: [`~/.config/opencode/skills/menu-factory/rules/global-menu-options.json`](http://${SERVER_HOST}:8080/editor/opencode/skills/menu-factory/rules/global-menu-options.json)

### Mandatory Menu Suffix

**Source**: triggers.yaml → menu_rules.mandatory_suffix

**EVERY skill menu MUST end with these 4 options:**

```json
[
  {"label": "🔧 Skill Improvement", "description": "Analyze usage patterns, failures, propose improvements"},
  {"label": "🩺 Skill Diagnosis", "description": "Run health checks, validate structure, check dependencies"},
  {"label": "🔍 Skill Discovery", "description": "Discover related docs, improve this menu, learn from your choices"},
  {"label": "Exit", "description": "Return to previous context"}
]
```

### Skill Improvement Features

When "🔧 Skill Improvement" is selected from any skill menu:

| Option | Description |
|--------|-------------|
| 📊 Analyze Recent Usage | Check last 7-14 days of usage, failures, decisions |
| 🔍 Identify Failure Patterns | Find recurring issues and root causes |
| 💡 Generate Proposals | Suggest threshold adjustments, reliability fixes |
| ✅ Apply Safe Improvements | Auto-apply low-risk changes |
| 📝 View Improvement History | Past changes and their outcomes |

### Skill Diagnosis Features

When "🩺 Skill Diagnosis" is selected from any skill menu:

| Option | Description |
|--------|-------------|
| 🏗️ Structure Check | Validate SKILL.md, required sections, YAML metadata |
| 📁 File Analysis | Check scripts, context, templates directories |
| 🔗 Dependency Check | Verify required dependencies are installed |
| 📊 Maturity Assessment | Determine current L0-L5 level |
| 🩺 Health Report | Overall skill health summary |

### Skill Discovery Features

When "🔍 Skill Discovery" is selected from any skill menu:

| Option | Description |
|--------|-------------|
| 📚 Discover Documents | Find related configs, docs, references |
| 🏗️ Analyze Skill Structure | Check maturity levels (L0-L5), file analysis |
| 🔄 Progressive Disclosure | 4-level context loading system |
| 🎯 Improve Current Menu | Learn from choices, suggest improvements |
| ✏️ Learn from Custom Inputs | Convert typed answers to menu options |
| 📊 View Discovery Stats | What's been discovered and stored |
| 🧹 Clean Context Files | Remove outdated or duplicate context |

### Skill Structure Analysis

Run structure analysis on all skills:

```bash
python3 ~/.config/opencode/skills/skill-discovery/scripts/analyze-structure.py --all
```

Current status (74 skills):
- **L5**: 1 skill (complete)
- **L4**: 2 skills (has templates/context)
- **L3**: 5 skills (has scripts)
- **L2**: 42 skills (structured with YAML)
- **L1**: 21 skills (SKILL.md only)
- **L0**: 3 skills (missing SKILL.md)

### Trigger Word

- `skill-discovery` - Open skill discovery menu
- `sd` - Short form (if configured)
