#!/usr/bin/env python3
"""
Publish a markdown file to Directus as a documentation page.
Reads DIRECTUS_URL and DIRECTUS_TOKEN from environment or /opt/pauly/.env

Usage:
    python3 publish_page.py /path/to/page.md
    python3 publish_page.py /path/to/page.md --dry-run
"""

import os
import re
import sys
import json
import argparse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

# Load .env if available
ENV_FILE = os.environ.get("PAULY_ENV", "/opt/pauly/.env")
if os.path.exists(ENV_FILE):
    for line in open(ENV_FILE):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, _, val = line.partition("=")
            os.environ.setdefault(key.strip(), val.strip())

DIRECTUS_URL = os.environ.get("DIRECTUS_URL") or f"http://localhost:{os.environ.get('PORT_DIRECTUS', '8056')}"
DIRECTUS_TOKEN = os.environ.get("DIRECTUS_TOKEN", "docs-api-token-change-me")


def extract_metadata(content: str) -> dict:
    lines = content.strip().split("\n")
    title = None
    for line in lines:
        if line.startswith("# "):
            title = line[2:].strip()
            break
    if not title:
        raise ValueError("No H1 title found. First line must be '# Title'")
    slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")[:50]
    if slug and slug[0].isdigit():
        slug = f"page-{slug}"
    excerpt = ""
    for line in lines:
        stripped = line.strip()
        if stripped and not stripped.startswith("#") and not stripped.startswith("**"):
            excerpt = stripped[:200]
            break
    tags = []
    category = None
    for line in lines:
        if line.strip().startswith("**Tags**:"):
            tags = [t.strip() for t in line.split(":", 1)[1].split(",")]
        if line.strip().startswith("**Category**:"):
            category = line.split(":", 1)[1].strip()
    return {"title": title, "slug": slug, "excerpt": excerpt, "tags": tags, "category": category}


def check_existing(slug: str) -> dict | None:
    url = f"{DIRECTUS_URL}/items/pages?filter[slug][_eq]={slug}&fields=id,title"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {DIRECTUS_TOKEN}"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
            return data["data"][0] if data["data"] else None
    except Exception:
        return None


def publish(payload: dict, existing_id: int | None = None) -> dict:
    url = f"{DIRECTUS_URL}/items/pages" + (f"/{existing_id}" if existing_id else "")
    method = "PATCH" if existing_id else "POST"
    req = urllib.request.Request(url, data=json.dumps(payload).encode(), method=method,
        headers={"Authorization": f"Bearer {DIRECTUS_TOKEN}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read())


def main():
    parser = argparse.ArgumentParser(description="Publish markdown to Directus")
    parser.add_argument("file", help="Path to markdown file")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--skip-quality", action="store_true")
    parser.add_argument("--status", default="published")
    args = parser.parse_args()

    filepath = Path(args.file)
    if not filepath.exists():
        print(f"ERROR: File not found: {filepath}"); sys.exit(1)

    content = filepath.read_text()
    meta = extract_metadata(content)

    print(f"Title:   {meta['title']}")
    print(f"Slug:    {meta['slug']}")
    print(f"Excerpt: {meta['excerpt'][:80]}...")
    print(f"Directus: {DIRECTUS_URL}")

    if args.dry_run:
        print("\n[dry-run] No publish."); return

    if not args.skip_quality:
        if len(content.split()) < 50:
            print("Quality gate: <50 words. Use --skip-quality"); sys.exit(1)

    payload = {k: v for k, v in {
        "title": meta["title"], "slug": meta["slug"], "status": args.status,
        "content": content, "excerpt": meta["excerpt"], "tags": meta["tags"] or None,
        "category": meta["category"],
        "date_published": datetime.now(timezone.utc).isoformat(),
    }.items() if v is not None}

    existing = check_existing(meta["slug"])
    if existing:
        print(f"\nPage exists (id: {existing['id']}), updating...")
        result = publish(payload, existing["id"])
    else:
        print("\nCreating new page...")
        result = publish(payload)

    page_id = result.get("data", {}).get("id", "?")
    print(f"\nPublished: id={page_id}, slug={meta['slug']}")

    port_astro = os.environ.get("PORT_ASTRO", "3003")
    print(f"URL: http://localhost:{port_astro}/docs/{meta['slug']}/")


if __name__ == "__main__":
    main()
