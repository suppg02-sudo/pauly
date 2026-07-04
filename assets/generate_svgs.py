"""Generate architecture and deployment-flow SVGs for Pauly README."""

import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape


# ── palette ──────────────────────────────────────────────────────────────
BG      = "#0a0020"
BG2     = "#120035"
CYAN    = "#00ffff"
PINK    = "#ff00ff"
GREEN   = "#00ff41"
WHITE   = "#e0e0ff"
DIM     = "#606080"
CARD_BG = "#1a0040"
BORDER  = "#2a0060"

FONT = "system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif"

def shadow_filter(diagram_id):
    return f"""<filter id="shadow_{diagram_id}" x="-10%" y="-10%" width="130%" height="130%">
  <feDropShadow dx="0" dy="2" stdDeviation="4" flood-color="#000" flood-opacity="0.6"/>
</filter>"""

def glow_filter(diagram_id, color=CYAN):
    c = color.lstrip("#")
    return f"""<filter id="glow_{diagram_id}" x="-50%" y="-50%" width="200%" height="200%">
  <feGaussianBlur stdDeviation="3" result="blur"/>
  <feFlood flood-color="#{c}" flood-opacity="0.5" result="col"/>
  <feComposite in="col" in2="blur" operator="in" result="glow"/>
  <feMerge><feMergeNode in="glow"/><feMergeNode in="SourceGraphic"/></feMerge>
</filter>"""

def defs_block(diagram_id):
    return f"""<defs>
  {shadow_filter(diagram_id)}
  {glow_filter(diagram_id, CYAN)}
  <linearGradient id="bgGrad_{diagram_id}" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0%" stop-color="{BG}"/>
    <stop offset="100%" stop-color="{BG2}"/>
  </linearGradient>
  <linearGradient id="cardGrad_{diagram_id}" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0%" stop-color="#220060"/>
    <stop offset="100%" stop-color="{CARD_BG}"/>
  </linearGradient>
</defs>"""


# ── helper builders ──────────────────────────────────────────────────────
def rect(x, y, w, h, rx=8, fill=CARD_BG, stroke=BORDER, sw=1.5, filt=None, op=None):
    parts = [f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"']
    if filt:
        parts.append(f' filter="url(#{filt})"')
    if op is not None:
        parts.append(f' opacity="{op}"')
    parts.append("/>")
    return "".join(parts)

def text(x, y, label, fill=WHITE, size=14, bold=False, anchor="middle", family=FONT):
    fw = " font-weight=\"700\"" if bold else ""
    return f'<text x="{x}" y="{y}" fill="{fill}" font-size="{size}" font-family="{family}" text-anchor="{anchor}"{fw}>{escape(str(label))}</text>'

def label_box(x, y, w, h, title, subtitle=None, color=CYAN, icon=None):
    """Card with optional icon emoji, title, subtitle."""
    lines = []
    lines.append(rect(x, y, w, h, fill=CARD_BG, stroke=color, sw=1.5, filt=f"shadow_{diagram_id}"))
    cx = x + w/2
    ty = y + h/2 - (6 if subtitle else 0)
    if icon:
        lines.append(text(cx, ty - 16, icon, size=20))
    lines.append(text(cx, ty, title, fill=color, size=13, bold=True))
    if subtitle:
        lines.append(text(cx, ty + 18, subtitle, fill=DIM, size=10))
    return "\n".join(lines)

def arrow(x1, y1, x2, y2, color=CYAN, label=None, dashed=False):
    dash = " stroke-dasharray=\"5,4\"" if dashed else ""
    mid_x, mid_y = (x1+x2)/2, (y1+y2)/2
    # If label is provided, shift line slightly to accommodate
    # For simplicity, just draw line and add label above midpoint
    lines = [f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{color}" stroke-width="2" marker-end="url(#arrowhead_{diagram_id})"{dash}/>']
    if label:
        lines.append(text(mid_x, mid_y - 10, label, fill=color, size=10))
    return "\n".join(lines)


# ═══════════════════════════════════════════════════════════════════════
# DIAGRAM 1: Architecture
# ═══════════════════════════════════════════════════════════════════════
diagram_id = "arch"
W, H = 800, 520

def build_architecture():
    marker = f"""<defs>
  <marker id="arrowhead_{diagram_id}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
    <path d="M 0 0 L 10 5 L 0 10 z" fill="{CYAN}"/>
  </marker>
  <marker id="arrowhead_pink_{diagram_id}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
    <path d="M 0 0 L 10 5 L 0 10 z" fill="{PINK}"/>
  </marker>
  {shadow_filter(diagram_id)}
  {glow_filter(diagram_id, CYAN)}
  <linearGradient id="bgGrad_{diagram_id}" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0%" stop-color="{BG}"/>
    <stop offset="100%" stop-color="{BG2}"/>
  </linearGradient>
  <linearGradient id="cardGrad_{diagram_id}" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0%" stop-color="#220060"/>
    <stop offset="100%" stop-color="{CARD_BG}"/>
  </linearGradient>
  <linearGradient id="dbGrad" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0%" stop-color="#003366"/>
    <stop offset="100%" stop-color="#001a33"/>
  </linearGradient>
</defs>"""

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="800" height="520">',
        marker,
        f'<rect width="{W}" height="{H}" fill="url(#bgGrad_{diagram_id})"/>',

        # ── Title ──
        text(W/2, 32, "Pauly Architecture", fill=CYAN, size=20, bold=True),
        text(W/2, 50, "Directus CMS + Astro Starlight Documentation Platform", fill=DIM, size=11),

        # ── LAYER 1: Directus CMS (left block) ──
        l1_x, l1_y, l1_w, l1_h = 40, 70, 280, 260
        parts.append(rect(l1_x, l1_y, l1_w, l1_h, fill="none", stroke=CYAN, sw=1, op=0.3))
        parts.append(text(l1_x + l1_w/2, l1_y + 22, "Directus CMS", fill=CYAN, size=14, bold=True))

        # PostgreSQL
        db_x, db_y, db_w, db_h = 60, 95, 240, 60
        parts.append(rect(db_x, db_y, db_w, db_h, fill="url(#dbGrad)", stroke="#0088cc", filt=f"shadow_{diagram_id}"))
        parts.append(text(db_x + 30, db_y + 28, "\U0001f5c4", size=18))
        parts.append(text(db_x + 50, db_y + 28, "PostgreSQL + pgvector", fill=WHITE, size=12, bold=True, anchor="start"))
        parts.append(text(db_x + 50, db_y + 46, "Structured content + embeddings", fill=DIM, size=10, anchor="start"))

        # Redis
        re_x, re_y, re_w, re_h = 60, 170, 240, 55
        parts.append(rect(re_x, re_y, re_w, re_h, fill="#330033", stroke=PINK, filt=f"shadow_{diagram_id}"))
        parts.append(text(re_x + 30, re_y + 26, "\u26a1", size=18))
        parts.append(text(re_x + 50, re_y + 26, "Redis Cache", fill=PINK, size=12, bold=True, anchor="start"))
        parts.append(text(re_x + 50, re_y + 44, "Session store + query cache", fill=DIM, size=10, anchor="start"))

        # Directus App
        da_x, da_y, da_w, da_h = 60, 240, 240, 55
        parts.append(rect(da_x, da_y, da_w, da_h, fill=CARD_BG, stroke=CYAN, filt=f"shadow_{diagram_id}"))
        parts.append(text(da_x + 30, da_y + 28, "\u2699\ufe0f", size=18))
        parts.append(text(da_x + 50, da_y + 28, "Directus App (REST API)", fill=CYAN, size=12, bold=True, anchor="start"))
        parts.append(text(da_x + 50, da_y + 44, "Port ${PORT_DIRECTUS}", fill=DIM, size=10, anchor="start"))

        # ── LAYER 2: Astro Starlight (right block) ──
        l2_x, l2_y, l2_w, l2_h = 420, 70, 320, 260
        parts.append(rect(l2_x, l2_y, l2_w, l2_h, fill="none", stroke=PINK, sw=1, op=0.3))
        parts.append(text(l2_x + l2_w/2, l2_y + 22, "Astro Starlight Docs Site", fill=PINK, size=14, bold=True))

        # Astro SSR
        as_x, as_y, as_w, as_h = 440, 95, 280, 60
        parts.append(rect(as_x, as_y, as_w, as_h, fill=CARD_BG, stroke=PINK, filt=f"shadow_{diagram_id}"))
        parts.append(text(as_x + 30, as_y + 28, "\ud83c\udf93", size=18))
        parts.append(text(as_x + 50, as_y + 28, "Astro (SSR Mode)", fill=PINK, size=12, bold=True, anchor="start"))
        parts.append(text(as_x + 50, as_y + 46, "Server-side rendered pages", fill=DIM, size=10, anchor="start"))

        # Starlight UI
        st_x, st_y, st_w, st_h = 440, 170, 280, 55
        parts.append(rect(st_x, st_y, st_w, st_h, fill=CARD_BG, stroke=CYAN, filt=f"shadow_{diagram_id}"))
        parts.append(text(st_x + 30, st_y + 26, "\ud83d\udcd6", size=18))
        parts.append(text(st_x + 50, st_y + 26, "Starlight UI", fill=CYAN, size=12, bold=True, anchor="start"))
        parts.append(text(st_x + 50, st_y + 44, "Sidebar, search, dark mode", fill=DIM, size=10, anchor="start"))

        # Directus SDK
        sd_x, sd_y, sd_w, sd_h = 440, 240, 280, 55
        parts.append(rect(sd_x, sd_y, sd_w, sd_h, fill=CARD_BG, stroke=GREEN, filt=f"shadow_{diagram_id}"))
        parts.append(text(sd_x + 30, sd_y + 28, "\ud83d\udd17", size=18))
        parts.append(text(sd_x + 50, sd_y + 28, "@directus/sdk", fill=GREEN, size=12, bold=True, anchor="start"))
        parts.append(text(sd_x + 50, sd_y + 44, "REST API client", fill=DIM, size=10, anchor="start"))

        # ── Data Flow Arrows ──
        # Directus → SDK
        parts.append(arrow(320, 267, 440, 267, CYAN, "REST API"))
        # SDK → Starlight
        parts.append(arrow(580, 295, 580, 225, GREEN, "content", dashed=False))

        # ── OpenCode Skills (bottom left) ──
        sk_x, sk_y, sk_w, sk_h = 40, 360, 320, 120
        parts.append(rect(sk_x, sk_y, sk_w, sk_h, fill="none", stroke=GREEN, sw=1, op=0.3))
        parts.append(text(sk_x + sk_w/2, sk_y + 22, "OpenCode Skills (CLI Management)", fill=GREEN, size=13, bold=True))

        skills = [
            ("directus-server", CYAN, "Manage Directus: sync, backup, schema"),
            ("astro-starlight", PINK, "Build, preview, deploy docs"),
        ]
        for i, (name, clr, desc) in enumerate(skills):
            sy = sk_y + 40 + i * 35
            parts.append(rect(sk_x + 15, sy, sk_w - 30, 28, fill=CARD_BG, stroke=clr, sw=1, filt=f"shadow_{diagram_id}"))
            parts.append(text(sk_x + sk_w/2, sy + 18, f"skills/{name}", fill=clr, size=11, bold=True))
            parts.append(text(sk_x + sk_w/2, sy + 18, f"  \u2014 {desc}", fill=DIM, size=10, anchor="start"))

        # ── Optional Phases (bottom right) ──
        op_x, op_y, op_w, op_h = 420, 360, 320, 120
        parts.append(rect(op_x, op_y, op_w, op_h, fill="none", stroke=PINK, sw=1, op=0.3, dash=True))
        parts.append(text(op_x + op_w/2, op_y + 22, "Optional Phases", fill=PINK, size=13, bold=True))

        opts = [
            ("Triggers (03)", "Word-activated command protocols"),
            ("Guardian (10)", "System + container health watchdog"),
            ("Monitoring (11)", "Prometheus + Grafana stack"),
        ]
        for i, (name, desc) in enumerate(opts):
            oy = op_y + 40 + i * 28
            parts.append(text(op_x + 20, oy + 18, name, fill=CYAN, size=11, bold=True, anchor="start"))
            parts.append(text(op_x + 140, oy + 18, desc, fill=DIM, size=10, anchor="start"))

        # Dashed arrows from core to optional
        parts.append(arrow(360, 420, 420, 400, PINK, "pluggable", dashed=True))

        # ── SVG end ──
        parts.append('</svg>')
    return "\n".join(parts)


# ═══════════════════════════════════════════════════════════════════════
# DIAGRAM 2: Deployment Flow
# ═══════════════════════════════════════════════════════════════════════
diagram_id2 = "deploy"
W2, H2 = 800, 480

def build_deployment():
    marker = f"""<defs>
  <marker id="arrowhead_{diagram_id2}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
    <path d="M 0 0 L 10 5 L 0 10 z" fill="{CYAN}"/>
  </marker>
  {shadow_filter(diagram_id2)}
  {glow_filter(diagram_id2, CYAN)}
  <linearGradient id="bgGrad_{diagram_id2}" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0%" stop-color="{BG}"/>
    <stop offset="100%" stop-color="{BG2}"/>
  </linearGradient>
  <linearGradient id="stepGrad" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0%" stop-color="#220060"/>
    <stop offset="100%" stop-color="{CARD_BG}"/>
  </linearGradient>
  <linearGradient id="verifyGrad" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0%" stop-color="#003300"/>
    <stop offset="100%" stop-color="#001a00"/>
  </linearGradient>
</defs>"""

    steps = [
        ("1", "Clone", "git clone pauly.git", CYAN, 50),
        ("2", "Configure", "cp .env.example .env\nbash detect-ports.sh", PINK, 180),
        ("3", "Detect Ports", "Auto-fill .env\nwith free ports", GREEN, 310),
        ("4", "Deploy Directus", "docker compose up -d\nPostgreSQL + Redis + API", CYAN, 440),
        ("5", "Deploy Astro", "docker compose up -d\nStarlight docs site", PINK, 570),
    ]

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W2} {H2}" width="800" height="480">',
        marker,
        f'<rect width="{W2}" height="{H2}" fill="url(#bgGrad_{diagram_id2})"/>',

        # Title
        text(W2/2, 32, "Pauly Deployment Flow", fill=CYAN, size=20, bold=True),
        text(W2/2, 50, "From clone to running docs platform in 5 steps", fill=DIM, size=11),

        # Step boxes (horizontal flow)
        box_w, box_h = 120, 100
        gap = 25
        total_w = 5 * box_w + 4 * gap
        start_x = (W2 - total_w) / 2
        start_y = 95

        for i, (num, title, desc, color, _) in enumerate(steps):
            sx = start_x + i * (box_w + gap)
            sy = start_y

            # Card
            parts.append(rect(sx, sy, box_w, box_h, fill=CARD_BG, stroke=color, filt=f"shadow_{diagram_id2}"))

            # Step number (circle)
            cx = sx + box_w/2
            circle_r = 14
            parts.append(f'<circle cx="{cx}" cy="{sy + 22}" r="{circle_r}" fill="{color}" opacity="0.15"/>')
            parts.append(text(cx, sy + 27, num, fill=color, size=13, bold=True))

            # Title
            parts.append(text(cx, sy + 52, title, fill=color, size=12, bold=True))

            # Description
            desc_lines = desc.split("\n")
            for li, line in enumerate(desc_lines):
                parts.append(text(cx, sy + 72 + li * 15, line, fill=DIM, size=10))

            # Arrow between boxes
            if i < len(steps) - 1:
                ax1 = sx + box_w
                ay = sy + box_h/2
                ax2 = ax1 + gap
                parts.append(arrow(ax1, ay, ax2, ay, CYAN))

        # ── Verification Checkpoints ──
        v_y = 260
        parts.append(rect(W2/2 - 250, v_y, 500, 65, fill="url(#verifyGrad)", stroke=GREEN, sw=1.5, filt=f"shadow_{diagram_id2}"))
        parts.append(text(W2/2, v_y + 24, "\u2705 Verification Checkpoints", fill=GREEN, size=14, bold=True))
        parts.append(text(W2/2, v_y + 46, "After step 4: curl /server/health    After step 5: curl / (200 OK)", fill=DIM, size=11))

        # Arrows from verify to each deploy step
        parts.append(arrow(400, v_y, 500 + 60, v_y - 30, GREEN, dashed=True))

        # ── Bottom: Init Script Shortcut ──
        bs_x, bs_y, bs_w, bs_h = W2/2 - 200, 360, 400, 65
        parts.append(rect(bs_x, bs_y, bs_w, bs_h, fill=CARD_BG, stroke=PINK, sw=2, filt=f"shadow_{diagram_id2}"))
        parts.append(text(bs_x + bs_w/2, bs_y + 28, "\u26a1 One-Command Bootstrap", fill=PINK, size=14, bold=True))
        parts.append(text(bs_x + bs_w/2, bs_y + 50, "optional/06-init-script/init.sh   (does everything)", fill=DIM, size=11))

        # Arrow from init to main flow
        parts.append(arrow(W2/2, bs_y, W2/2, start_y + box_h + 10, PINK, "fast path", dashed=True))

        parts.append('</svg>')
    return "\n".join(parts)


# ── Write files ──────────────────────────────────────────────────────
arch_svg = build_architecture()
deploy_svg = build_deployment()

with open("/root/pauly/assets/architecture.svg", "w") as f:
    f.write(arch_svg)
with open("/root/pauly/assets/deployment-flow.svg", "w") as f:
    f.write(deploy_svg)

print("✅ architecture.svg written")
print("✅ deployment-flow.svg written")
print(f"   arch: {len(arch_svg)} bytes")
print(f"   deploy: {len(deploy_svg)} bytes")
