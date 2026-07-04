#!/usr/bin/env python3
"""Generate SVG diagrams for Pauly README."""
import os

DIR = os.path.dirname(__file__)

class SVGBuilder:
    def __init__(self, width, height, bg_color="#f8fafc"):
        self.width = width
        self.height = height
        self.parts = []
        self.parts.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" style="width:100%;max-width:{width}px;height:auto;display:block;">')
        if bg_color:
            self.parts.append(f'<rect width="{width}" height="{height}" fill="{bg_color}"/>')
        self._add_defs()

    def _esc(self, text):
        return text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")

    def _add_defs(self):
        self.parts.append('''<defs>
<filter id="glow"><feGaussianBlur stdDeviation="2" result="blur"/><feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
<filter id="shadow"><feDropShadow dx="0" dy="2" stdDeviation="3" flood-opacity="0.1"/></filter>
<marker id="arrow" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto"><polygon points="0 0, 10 3.5, 0 7" fill="#64748b"/></marker>
<marker id="arrow-cyan" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto"><polygon points="0 0, 10 3.5, 0 7" fill="#06b6d4"/></marker>
</defs>''')

    def box(self, x, y, w, h, fill, stroke, text, text_color="#1e293b", font_size=14, bold=False, rx=8):
        safe = self._esc(text)
        fw = 'font-weight="bold"' if bold else ""
        self.parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="1.5" filter="url(#shadow)"/>')
        self.parts.append(f'<text x="{x+w/2}" y="{y+h/2+5}" text-anchor="middle" font-family="system-ui,sans-serif" font-size="{font_size}" fill="{text_color}" {fw}>{safe}</text>')

    def arrow(self, x1, y1, x2, y2, stroke="#94a3b8", dash=None, marker="arrow"):
        attr = f'stroke="{stroke}" stroke-width="1.5" marker-end="url(#{marker})"'
        if dash: attr += f' stroke-dasharray="{dash}"'
        self.parts.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" {attr}/>')

    def curved_arrow(self, x1, y1, x2, y2, stroke="#94a3b8", marker="arrow"):
        cx = (x1 + x2) / 2
        path = f'M {x1} {y1} Q {cx} {y1 if y1 < y2 else y2} {x2} {y2}'
        self.parts.append(f'<path d="{path}" fill="none" stroke="{stroke}" stroke-width="1.5" marker-end="url(#{marker})"/>')

    def text(self, x, y, content, size=12, fill="#64748b", anchor="middle", bold=False):
        safe = self._esc(content)
        fw = 'font-weight="bold"' if bold else ""
        self.parts.append(f'<text x="{x}" y="{y}" text-anchor="{anchor}" font-family="system-ui,sans-serif" font-size="{size}" fill="{fill}" {fw}>{safe}</text>')

    def label(self, x, y, w, h, text, fill="#64748b", size=11):
        safe = self._esc(text)
        self.parts.append(f'<text x="{x+w/2}" y="{y+h+16}" text-anchor="middle" font-family="system-ui,sans-serif" font-size="{size}" fill="{fill}">{safe}</text>')

    def title(self, x, y, text, size=18, fill="#0f172a"):
        safe = self._esc(text)
        self.parts.append(f'<text x="{x}" y="{y}" text-anchor="middle" font-family="system-ui,sans-serif" font-size="{size}" font-weight="bold" fill="{fill}">{safe}</text>')

    def render(self):
        self.parts.append("</svg>")
        return "\n".join(self.parts)

    def save(self, path):
        with open(path, "w") as f:
            f.write(self.render())
        print(f"  Saved: {path}")


def architecture_diagram():
    d = SVGBuilder(800, 520)

    # Title
    d.title(400, 35, "Pauly Architecture", 22)

    # === LEFT SIDE: Directus Stack ===
    dx, dy = 40, 70
    d.box(dx, dy, 280, 50, "#3b82f620", "#3b82f6", "Directus CMS", font_size=15, bold=True)
    d.label(dx, dy, 280, 50, "Headless CMS Admin + REST API", size=11)

    # Database boxes
    d.box(dx, dy+85, 130, 42, "#14b8a620", "#14b8a6", "PostgreSQL + pgvector")
    d.label(dx, dy+85, 130, 42, "Structured content + embeddings", size=10)

    d.box(dx+150, dy+85, 130, 42, "#f9731620", "#f97316", "Redis Cache")
    d.label(dx+150, dy+85, 130, 42, "Session + query cache", size=10)

    # === RIGHT SIDE: Astro Stack ===
    ax, ay = 480, 70
    d.box(ax, ay, 280, 50, "#8b5cf620", "#8b5cf6", "Astro Starlight", font_size=15, bold=True)
    d.label(ax, ay, 280, 50, "SSR Docs Site + UI", size=11)

    # Astro components
    d.box(ax, ay+85, 130, 42, "#8b5cf620", "#8b5cf6", "Dynamic Pages")
    d.label(ax, ay+85, 130, 42, "Fetched from Directus API", size=10)

    d.box(ax+150, ay+85, 130, 42, "#8b5cf620", "#8b5cf6", "Search + Sidebar")
    d.label(ax+150, ay+85, 130, 42, "Full-text + auto-nav", size=10)

    # === CENTER ARROW: Directus -> Astro ===
    cx1, cy = dx + 280, dy + 25
    cx2 = ax
    d.curved_arrow(cx1, cy, cx2, cy, stroke="#06b6d4", marker="arrow-cyan")
    d.text(400, dy + 15, "REST API", size=11, fill="#0891b2", bold=True)
    d.text(400, dy + 30, "Content fetched at request time", size=10, fill="#64748b")

    # === BOTTOM: OpenCode Skills ===
    sy = 240
    d.box(160, sy, 480, 50, "#06b6d420", "#06b6d4", "OpenCode Skills", font_size=15, bold=True)
    d.label(160, sy, 480, 50, "CLI Management Interface", size=11)

    # Skill boxes
    skill_y = sy + 65
    skill_w = 140
    skill_gap = 20
    total_skill_w = 3 * skill_w + 2 * skill_gap
    start_x = (800 - total_skill_w) / 2
    skills = [
        ("directus-server", "Manage Directus", "#3b82f620", "#3b82f6"),
        ("astro-starlight", "Manage Astro", "#8b5cf620", "#8b5cf6"),
        ("guardian", "System Health", "#10b98120", "#10b981"),
    ]
    for i, (name, desc, fill, stroke) in enumerate(skills):
        sx = start_x + i * (skill_w + skill_gap)
        d.box(sx, skill_y, skill_w, 36, fill, stroke, name, font_size=13, bold=True)
        d.label(sx, skill_y, skill_w, 36, desc, size=10)

    # === BOTTOM: Optional Phases ===
    py = 390
    d.text(400, py, "Optional Phases", size=14, fill="#0f172a", bold=True)

    phases = [
        ("01-agents-md", "Agent Rules"),
        ("02-context-files", "Standards"),
        ("03-triggers", "16 Trigger Cmds"),
        ("04-skills", "Skills Install"),
        ("05-mcp-config", "MCP Servers"),
    ]
    phase_w = 140
    phase_gap = 14
    total_pw = len(phases) * phase_w + (len(phases) - 1) * phase_gap
    px_start = (800 - total_pw) / 2

    for i, (name, desc) in enumerate(phases):
        px = px_start + i * (phase_w + phase_gap)
        d.box(px, py+20, phase_w, 32, "#f1f5f9", "#cbd5e1", name, font_size=11, text_color="#475569")
        d.label(px, py+20, phase_w, 32, desc, size=10, fill="#94a3b8")

    # Second row of phases
    phases2 = [
        ("06-init-script", "Bootstrap"),
        ("07-pa-skill", "PA Dashboard"),
        ("08-react-admin", "Admin Panel"),
        ("09-setuprefine", "Self-Analysis"),
        ("10-guardian", "Monitoring"),
    ]
    py2 = py + 78
    for i, (name, desc) in enumerate(phases2):
        px = px_start + i * (phase_w + phase_gap)
        d.box(px, py2, phase_w, 32, "#f1f5f9", "#cbd5e1", name, font_size=11, text_color="#475569")
        d.label(px, py2, phase_w, 32, desc, size=10, fill="#94a3b8")

    # Legend
    ly = py2 + 65
    d.text(400, ly, "All ports and URLs driven by .env — nothing hardcoded", size=12, fill="#64748b")

    d.save(os.path.join(DIR, "architecture.svg"))


def deployment_flow():
    d = SVGBuilder(800, 520)

    d.title(400, 35, "Pauly Deployment Flow", 22)

    # Steps - 5 boxes in a row
    steps = [
        ("1. Clone", "git clone", "Get the repo", "#3b82f620", "#3b82f6"),
        ("2. Configure", "cp .env.example .env", "Set variables", "#14b8a620", "#14b8a6"),
        ("3. Detect Ports", "detect-ports.sh", "Auto-find free ports", "#f9731620", "#f97316"),
        ("4. Deploy Directus", "docker compose up -d", "CMS + DB + Cache", "#8b5cf620", "#8b5cf6"),
        ("5. Deploy Astro", "docker compose up -d", "Docs Frontend", "#10b98120", "#10b981"),
    ]

    step_w = 130
    step_h = 80
    step_gap = 25
    total_w = len(steps) * step_w + (len(steps) - 1) * step_gap
    start_x = (800 - total_w) / 2
    y = 80

    for i, (title, cmd, desc, fill, stroke) in enumerate(steps):
        sx = start_x + i * (step_w + step_gap)
        d.box(sx, y, step_w, step_h, fill, stroke, title, font_size=13, bold=True)
        d.text(sx + step_w/2, y + step_h/2 + 22, cmd, size=10, fill="#475569")
        d.text(sx + step_w/2, y + step_h/2 + 38, desc, size=10, fill="#64748b")

        # Arrow between steps
        if i < len(steps) - 1:
            ax1 = sx + step_w
            ax2 = start_x + (i + 1) * (step_w + step_gap)
            d.arrow(ax1, y + step_h/2, ax2, y + step_h/2, stroke="#06b6d4", marker="arrow-cyan")

    # === Verification section ===
    vy = 210
    d.text(400, vy, "Verification Checkpoints", size=14, fill="#0f172a", bold=True)

    checks = [
        ("Directus Health", "curl /server/health", "#3b82f620", "#3b82f6"),
        ("Astro Health", "curl / (HTTP 200)", "#8b5cf620", "#8b5cf6"),
        ("Optional: init.sh", "Full bootstrap", "#10b98120", "#10b981"),
    ]

    cw = 200
    ch = 50
    cgap = 40
    total_cw = len(checks) * cw + (len(checks) - 1) * cgap
    cx_start = (800 - total_cw) / 2

    for i, (title, cmd, fill, stroke) in enumerate(checks):
        cx = cx_start + i * (cw + cgap)
        cy = vy + 20
        d.box(cx, cy, cw, ch, fill, stroke, title, font_size=13, bold=True)
        d.text(cx + cw/2, cy + ch/2 + 20, cmd, size=10, fill="#475569")

        # Arrow from deploy steps to verification
        if i == 0:
            step_x = start_x + 3 * (step_w + step_gap) + step_w  # after step 4 (Directus)
            d.curved_arrow(step_x, y + step_h, step_x, cy + ch, stroke="#94a3b8", marker="arrow")
        if i == 1:
            step_x = start_x + 4 * (step_w + step_gap) + step_w  # after step 5 (Astro)
            d.curved_arrow(step_x, y + step_h, step_x, cy + ch, stroke="#94a3b8", marker="arrow")

    # === Optional phases section ===
    oy = 365
    d.text(400, oy, "Post-Deployment: Optional Phases", size=14, fill="#0f172a", bold=True)

    optional_items = [
        "Agent Config", "Context Files", "Triggers", "MCP Servers",
        "PA Dashboard", "React Admin", "Guardian"
    ]
    o_box_w = 100
    o_box_gap = 12
    total_ow = len(optional_items) * o_box_w + (len(optional_items) - 1) * o_box_gap
    ox_start = (800 - total_ow) / 2

    for i, item in enumerate(optional_items):
        ox = ox_start + i * (o_box_w + o_box_gap)
        d.box(ox, oy + 20, o_box_w, 32, "#f1f5f9", "#cbd5e1", item, font_size=11, text_color="#475569")

    # Bottom text
    d.text(400, 495, "bash optional/<phase>/scripts/install.sh (or: init.sh --skills for all)", size=12, fill="#64748b")

    d.save(os.path.join(DIR, "deployment-flow.svg"))


if __name__ == "__main__":
    print("Generating SVG diagrams...")
    architecture_diagram()
    deployment_flow()
    print("Done.")
