# Triggers — Word-Activated Command Protocols

Installs a set of **word triggers** that activate predefined agent workflows. Each trigger is a short word (e.g. `?`, `co`, `u`) that the agent recognises and responds to with a structured protocol.

## Why Triggers

Triggers let you type 1-3 characters to get complex, consistent behaviour — no need to describe what you want each time. The agent follows a documented protocol instead of guessing.

## What's Installed

| Trigger | Word(s) | Purpose | Category |
|---------|---------|---------|----------|
| Continue | `co` | Resume most recent task with full context recovery | Core Workflow |
| What Next | `?`, `what next`, `wn` | Analyse state, surface priorities, recommend next step | Core Workflow |
| Update | `u`, `update` | Review session work, propose skill/context updates | Self-Improvement |
| Improve | `improve` | Improve ANY component — skills, prompts, menus, config | Self-Improvement |
| Brainstorm | `bs`, `brainstorm` | Quick ideation or structured design sessions | Creative |
| Session | `session` | Session recovery after compaction — diagnose and fix | Reliability |
| Deferred | `d`, `deferred` | Parked task management — review, resume, archive | Task Management |
| Flow | `flow` | Execution tracing and analysis | Analysis |
| Smooth | `smooth` | Polish rough edges in workflows | Analysis |
| Guardian | `g`, `guardian` | System health menu — status, report, improvements | Operations |
| NextExplorer | `nx`, `next-explorer` | Redisplay recent session files as clickable links | Navigation |
| Menu | `menu` | Central menu hub for all options and skills | Navigation |
| Visual Companion | `vc`, `visual-companion` | Browser-based diagram generation | Creative |
| Cron | `cron` | View, edit, monitor scheduled tasks | Operations |
| Space | `space`, `sp` | Disk space analysis and cleanup | Operations |
| SVG | `svg`, `diagram` | Publication-ready SVG diagrams from natural language | Creative |

## Installation

```bash
# Install all trigger context files
bash /opt/pauly/optional/03-triggers/scripts/install.sh

# Verify installation
bash /opt/pauly/optional/03-triggers/scripts/install.sh --verify

# Uninstall
bash /opt/pauly/optional/03-triggers/scripts/install.sh --uninstall
```

## How It Works

1. **Context files** (`.md`) are installed to `<opencode-config>/agents/context/` — each defines a trigger's protocol
2. **Trigger registry** is installed as `trigger-words.md` — the master table of all triggers
3. **AGENTS.md** is updated with a `## Word Triggers` section listing the trigger commands

## CRITICAL: Trigger Detection & Response

**When the user types ANY of the following, you MUST read the corresponding trigger file:**

| Input | Trigger | Action |
|-------|---------|--------|
| `co` | Continue | Read `continue-instructions.md` and follow the protocol |
| `?` | What Next | Read `what-next-instructions.md` and follow the protocol |
| `u` | Update | Read `update-instructions.md` and follow the protocol |
| `improve` | Improve | Read `improve-instructions.md` and follow the protocol |
| `bs` | Brainstorm | Read `brainstorm-instructions.md` and follow the protocol |
| `session` | Session | Read `session-recovery.md` and follow the protocol |
| `d` | Deferred | Read `deferred-options.md` and follow the protocol |
| `flow` | Flow | Read `flow-instructions.md` and follow the protocol |
| `smooth` | Smooth | Read `smooth-instructions.md` and follow the protocol |
| `g` | Guardian | Read `guardian-instructions.md` and follow the protocol |
| `nx` | NextExplorer | Read `next-explorer-instructions.md` and follow the protocol |
| `menu` | Menu | Read `central-menu.md` and follow the protocol |
| `vc` | Visual Companion | Read `visual-companion-instructions.md` and follow the protocol |
| `cron` | Cron | Read `cron-instructions.md` and follow the protocol |
| `space` | Space | Read `space-instructions.md` and follow the protocol |
| `svg` | SVG | Read `svg-instructions.md` and follow the protocol |
| `>` | Continue (alias) | Read `continue-instructions.md` and follow the protocol |
| `1` | What Next (alias) | Read `what-next-instructions.md` and follow the protocol |
| `2` | Update (alias) | Read `update-instructions.md` and follow the protocol |

**Detection Rules:**
- Trigger words can be 1-3 characters (`>`, `1`, `2`, `co`, `?`, `u`, etc.)
- Triggers are case-sensitive (`co` ≠ `CO`)
- Triggers can appear anywhere in the message (start, middle, end)
- If multiple triggers in one message, process each one
- Always read the trigger file FIRST, then follow the protocol exactly

**Response Format:**
1. Detect trigger word(s) in user message
2. Read the corresponding `.md` file from `~/.config/opencode/agents/context/`
3. Follow the protocol in that file
4. Execute the trigger's workflow

## Configuration

Set `OPENCODE_CONFIG_DIR` in `.env` to override the OpenCode config directory (default: `~/.config/opencode`).

## Superpowers Note

Some triggers (`vc`/visual-companion, `svg`, `bs`/brainstorm) rely on OpenCode **superpowers** — additional skill packages installed separately. The context files reference these skills but do not install them. Run `optional/04-skills/scripts/install.sh` to install the required skills.
