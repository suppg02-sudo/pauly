#!/usr/bin/env python3
"""Generate generalized trigger context template files from existing source."""
import os
import re
import shutil

TEMPLATES_DIR = os.path.join(os.path.dirname(__file__), "..", "templates")
SOURCE_DIR = os.path.expanduser("~/.config/opencode/agents/context")

GENERALIZED_PATTERNS = [
    ("http://ubuntu4:3002", "http://${SERVER_HOST}:${PORT_ASTRO}"),
    ("http://ubuntu4:8055", "http://${SERVER_HOST}:${PORT_DIRECTUS}"),
    ("http://localhost:8055", "http://${SERVER_HOST}:${PORT_DIRECTUS}"),
    ("http://localhost:3002", "http://localhost:${PORT_ASTRO}"),
    ("port 3002", "port ${PORT_ASTRO}"),
    ("port 8055", "port ${PORT_DIRECTUS}"),
    ("localhost:3002", "localhost:${PORT_ASTRO}"),
    ("localhost:8055", "localhost:${PORT_DIRECTUS}"),
    (":3002/", ":${PORT_ASTRO}/"),
    (":8055/", ":${PORT_DIRECTUS}/"),
    ("/root/.config/opencode", "${OPENCODE_CONFIG_DIR}"),
    ("/root/", "${HOME}/"),
    ("/root/pauly", "${PAULY_ROOT}"),
    ("/media/docker/astro-blog", "${ASTRO_BLOG_DIR}"),
    ("/usr/local/bin/guardian-status.sh", "${GUARDIAN_SCRIPT}"),
    ("ubuntu4", "${SERVER_HOST}"),
]

TRIGGERS = {
    "continue-instructions.md": {
        "triggers": ["co"],
        "purpose": "Resume or continue the most recent/current task with full context recovery",
        "phases": [
            "Read current_state.md",
            "Check active todos in current session",
            "List active flows from hybrid_tracker",
            "List deferred items",
            "Check session conversation for last incomplete task",
            "Identify what to continue — classify as resumable task, pending question, or parked item",
            "Confirm with user or fall through to clarifying questions",
        ],
    },
    "what-next-instructions.md": {
        "triggers": ["?", "what next", "wn"],
        "purpose": "Analyse current state, surface priorities, recommend next steps",
        "phases": [
            "Ask clarifying questions: horizon (right now / today / this week)",
            "Ask output preference: single step / ranked list / full analysis",
            "Read current_state.md for recently completed items",
            "List deferred items",
            "Check active flows",
            "Check recent decisions",
            "Check active GitHub issues if relevant",
            "Present structured analysis with recommended next step",
        ],
    },
    "update-instructions.md": {
        "triggers": ["u", "update"],
        "purpose": "Review session work, propose skill/context updates with per-item approval",
        "phases": [
            "Gather recent context: current_state.md, session history, decisions, flows",
            "Check what skills were loaded and files edited this session",
            "Build update map across categories: skills, triggers, context files, env, menus, schemas, wiki",
            "Present intelligent suggestions via question tool",
            "Apply approved changes with smallest possible edits",
        ],
    },
    "improve-instructions.md": {
        "triggers": ["improve"],
        "purpose": "Analyse and improve ANY system component — skills, prompts, menus, config, triggers, docs, workflows",
        "phases": [
            "Ask clarifying questions: what to improve (skill / config / menu / workflow / auto-detect)",
            "Ask what aspect to focus on (structure / completeness / token efficiency / error prevention / full review)",
            "Analyse the target for gaps, redundancies, and anti-patterns",
            "Present structured improvement proposals via question tool",
            "Apply approved changes",
        ],
    },
    "brainstorm-instructions.md": {
        "triggers": ["bs", "brainstorm"],
        "purpose": "Creative exploration and ideation — Quick Think or structured design sessions",
        "phases": [
            "Context injection: load system identity, current state, relevant config",
            "Ask clarifying questions: mode (Quick Think / structured design / schema design)",
            "Quick Think mode: generate 5 ideas in 2 minutes with evaluation",
            "Structured mode: progressive disclosure with research, schema, alternatives",
            "Present results with top recommendation",
        ],
    },
    "session-recovery.md": {
        "triggers": ["session"],
        "purpose": "Recover from session compaction or resume — diagnose incomplete items, fix, verify, report",
        "phases": [
            "Read state: Goal, Instructions, Discoveries, Accomplished list",
            "Diagnose each item: compile check .py files, syntax check .sh files",
            "Read around error lines for context",
            "Build todo list: broken = high, pending = medium, verify = high",
            "Fix with smallest possible edits, verify compile after each",
            "Verify full pipeline: extraction → publish → gates → resolve → notify",
            "Report status with updated accomplished list",
        ],
    },
    "deferred-options.md": {
        "triggers": ["d", "deferred"],
        "purpose": "Show and manage deferred/parked items — review, resume, bump priority, or archive",
        "phases": [
            "Run deferred list to get all active items",
            "Present each as question tool option with priority badge and category",
            "On selection: show full details with context and memories",
            "Offer action menu: Activate, Bump priority, Update, Archive, Back, Exit",
        ],
    },
    "flow-instructions.md": {
        "triggers": ["flow"],
        "purpose": "Trace, document, and analyse how tasks execute from request to completion",
        "phases": [
            "Ask clarifying questions: what to trace (last session / last task / specific / current / comparison)",
            "Gather execution data: session conversation, logs, skill events, timing",
            "Analyse: identify bottlenecks, unnecessary steps, error patterns",
            "Present findings with tool call timeline and improvement suggestions",
        ],
    },
    "smooth-instructions.md": {
        "triggers": ["smooth"],
        "purpose": "Identify and fix friction, clunkiness, and rough edges in recent execution",
        "phases": [
            "Ask clarifying questions: what felt rough (last task / workflow / skill / trigger / auto-detect)",
            "Identify roughness type: too many questions, wrong order, unnecessary steps, missing context, error recovery",
            "Analyse for improvements",
            "Present fix proposals via question tool",
            "Apply approved changes",
        ],
    },
    "guardian-instructions.md": {
        "triggers": ["g", "guardian"],
        "purpose": "Present Guardian system health menu — reports, status, improvements",
        "phases": [
            "Verify guardian script exists at ${GUARDIAN_SCRIPT:-/usr/local/bin/guardian-status.sh}",
            "Run guardian-status.sh with appropriate mode for each option",
            "Present menu: Read Report, Improvements, Check Status, Blog Post, Extend Guardian, Exit",
        ],
        "footer": "\n## Data Source\n\nThe guardian script at `${GUARDIAN_SCRIPT:-/usr/local/bin/guardian-status.sh}` provides:\n- `report` — latest logs from all watchers\n- `status` — system health snapshot\n- `improvements` — diagnostic recommendations\n\nSet `GUARDIAN_SCRIPT` in `.env` to override the path.",
    },
    "next-explorer-instructions.md": {
        "triggers": ["nx", "next-explorer"],
        "purpose": "Redisplay recent session files as clickable links for quick navigation",
        "phases": [
            "Scan current session for all file paths referenced (read, edited, written, or mentioned)",
            "Convert each path to its NextExplorer URL using volume mappings",
            "Deduplicate and list most recent first",
            "Display as markdown list of clickable links",
        ],
        "footer": "\n## Volume Mapping\n\nPaths are mapped to URLs using these rules:\n- `${OPENCODE_CONFIG_DIR}/` → volume `opencode`\n- `${ASTRO_BLOG_DIR:-/media/docker/astro-blog}/` → volume `docker`\n- All other paths → volume `storage`\n\nConfigure volume mappings in `.env` as `NEXTEXPLORER_VOLUMES` (comma-separated `prefix:volume-name` pairs).",
    },
    "central-menu.md": {
        "triggers": ["menu"],
        "purpose": "Present the central menu hub — all available options, skills, and tools in one place",
        "phases": [
            "Read the installed skills and triggers from the opencode config",
            "Build a categorized menu of available commands",
            "Present via question tool with pagination for mobile",
        ],
    },
    "visual-companion-instructions.md": {
        "triggers": ["vc", "visual-companion"],
        "purpose": "Start visual companion server for browser-based diagrams, mockups, and architecture flows",
        "phases": [
            "Start the visual companion server",
            "Parse port from output",
            "Write HTML content to content directory",
            "Navigate browser → screenshot → show user",
        ],
        "requires_skill": "visual-companion",
    },
    "cron-instructions.md": {
        "triggers": ["cron"],
        "purpose": "Comprehensive cron job management — view, edit, monitor, and link scheduled tasks to skills",
        "phases": [
            "List current cron jobs from crontab",
            "Present menu: view, edit, add, remove, link to skill",
            "Apply changes to crontab",
        ],
    },
    "space-instructions.md": {
        "triggers": ["space", "sp"],
        "purpose": "Disk space analysis and cleanup assistant",
        "phases": [
            "Check disk usage with df -h",
            "Find largest directories with du",
            "Identify cleanup candidates (logs, temp files, Docker cache)",
            "Present options: Docker cleanup, log rotation, temp file removal, manual review",
        ],
    },
    "svg-instructions.md": {
        "triggers": ["svg", "diagram"],
        "purpose": "Generate publication-ready SVG diagrams (flowcharts, architectures, system flows) from natural language or Python scripts",
        "phases": [
            "Understand the diagram requirement",
            "Generate SVG using Python (svgwrite or manual XML)",
            "Save to file and display to user",
        ],
        "requires_skill": "svg",
    },
}


def generalize(text: str, source_file: str) -> str:
    """Generalize a source context file for template use."""
    for old, new in GENERALIZED_PATTERNS:
        text = text.replace(old, new)
    # Replace trigger-specific things
    basename = os.path.basename(source_file)
    if basename in TRIGGERS:
        info = TRIGGERS[basename]
        triggers_str = ", ".join(f"`{t}`" for t in info["triggers"])
        # Update the header line
        for old_prefix in ("# ", "# Trigger: ", "# "):
            idx = text.find(old_prefix)
            if idx != -1:
                end = text.find("\n", idx)
                if end != -1:
                    text = text[:idx] + f"# {info['triggers'][0]} — {info['purpose']}" + text[end:]
                break
        # Update trigger line
        trigger_line_patterns = [
            "**Trigger**:",
            "> **Trigger**:",
            "<!-- Trigger:",
        ]
        for pattern in trigger_line_patterns:
            idx = text.find(pattern)
            if idx != -1 and "Trigger:" in text[idx:idx+20]:
                end = text.find("\n", idx)
                if end != -1:
                    replacement = f"**Trigger**: {triggers_str} | **Purpose**: {info['purpose']}"
                    text = text[:idx] + replacement + text[end:]
                break
        # Add general header if missing
        if "# " not in text[:text.find("\n")]:
            text = f"# {info['triggers'][0]} — {info['purpose']}\n\n{text}"
    return text


def generate_template(trigger_key: str, info: dict) -> str:
    """Generate a fresh template context file."""
    triggers_str = ", ".join(f"`{t}`" for t in info["triggers"])
    lines = [
        f"# {info['triggers'][0]} — {info['purpose']}",
        "",
        f"> **Trigger**: {triggers_str} | **Purpose**: {info['purpose']}",
        "> **When to use**: (describe when user should type this trigger)",
        "",
        "---",
        "",
        "## How It Works",
        "",
        "When the user types this trigger, follow the phases below.",
        "",
        "---",
        "",
    ]

    for i, phase in enumerate(info.get("phases", [])):
        lines.append(f"### Phase {i}")
        lines.append("")
        lines.append(f"{phase}")
        lines.append("")

    if info.get("requires_skill"):
        lines.append("---")
        lines.append("")
        lines.append("## Dependencies")
        lines.append("")
        lines.append(f"This trigger requires the **{info['requires_skill']}** skill. If not installed, report the missing dependency to the user.")
        lines.append("")

    if info.get("footer"):
        lines.append(info["footer"].strip())
        lines.append("")

    return "\n".join(lines)


def main():
    os.makedirs(TEMPLATES_DIR, exist_ok=True)
    generated = 0
    copied = 0

    for filename, info in TRIGGERS.items():
        source_path = os.path.join(SOURCE_DIR, filename)
        template_path = os.path.join(TEMPLATES_DIR, filename)

        if os.path.exists(source_path):
            try:
                with open(source_path, "r") as f:
                    content = f.read()
                # Generalize the content
                content = generalize(content, source_path)
                with open(template_path, "w") as f:
                    f.write(content)
                print(f"  ✓ {filename} — generalized from source ({len(content)}B)")
                copied += 1
            except Exception as e:
                print(f"  ! {filename} — generalization failed: {e}, generating fresh")
                content = generate_template(filename, info)
                with open(template_path, "w") as f:
                    f.write(content)
                print(f"  ✓ {filename} — generated fresh ({len(content)}B)")
                generated += 1
        else:
            content = generate_template(filename, info)
            with open(template_path, "w") as f:
                f.write(content)
            print(f"  ✓ {filename} — generated fresh ({len(content)}B)")
            generated += 1

    print(f"\n  Done: {copied} generalized + {generated} fresh = {copied + generated} templates")


if __name__ == "__main__":
    main()
