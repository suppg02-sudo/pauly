#!/bin/bash
###############################################################################
# analyse.sh — Setup Refine consistency checker
# Runs all non-interactive checks and prints a report. Does NOT modify files.
###############################################################################

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ISSUES=0
WARNINGS=0

echo "═══════════════════════════════════════════════════════════"
echo "  SETUP REFINE — Consistency Report"
echo "  $(date)"
echo "═══════════════════════════════════════════════════════════"
echo ""

# ── 1. Port Variable Consistency ─────────────────────────────────────────────
echo -e "${CYAN}[1] Port Variables${NC}"

# Find all ${PORT_*} in compose files
COMPOSE_PORTS=$(grep -rohE '\$\{PORT_[A-Z_]+' directus/ astro-docs/ optional/*/  --include='docker-compose.yml' 2>/dev/null | sed 's/${//' | sort -u || true)
ENV_PORTS=$(grep -E '^PORT_' .env.example 2>/dev/null | cut -d= -f1 | sort -u)

for port in $COMPOSE_PORTS; do
  if echo "$ENV_PORTS" | grep -q "^${port}$"; then
    echo -e "  ${GREEN}OK${NC}    $port defined in .env.example"
  else
    echo -e "  ${RED}MISS${NC}  $port used in compose but MISSING from .env.example"
    ISSUES=$((ISSUES + 1))
  fi
done
echo ""

# ── 2. Credential Variable Consistency ───────────────────────────────────────
echo -e "${CYAN}[2] Credential Variables${NC}"

COMPOSE_CREDS=$(grep -rohE '\$\{[A-Z_]*(PASSWORD|TOKEN|SECRET|KEY)[A-Z_]*' directus/ astro-docs/ optional/*/ --include='docker-compose.yml' --include='*.sh' --include='*.yml' 2>/dev/null | sed 's/${//' | sort -u || true)
ENV_CREDS=$(grep -E '(PASSWORD|TOKEN|SECRET|KEY)' .env.example 2>/dev/null | cut -d= -f1 | sort -u)

for cred in $COMPOSE_CREDS; do
  if echo "$ENV_CREDS" | grep -q "^${cred}$"; then
    echo -e "  ${GREEN}OK${NC}    $cred defined in .env.example"
  else
    echo -e "  ${RED}MISS${NC}  $cred used but MISSING from .env.example"
    ISSUES=$((ISSUES + 1))
  fi
done
echo ""

# ── 3. Default Passwords Check ───────────────────────────────────────────────
echo -e "${CYAN}[3] Default Passwords${NC}"

if grep -qiE 'admin123|change-me|CHANGE_ME|password123|directus123' .env.example 2>/dev/null; then
  echo -e "  ${RED}FAIL${NC}  Default/placeholder credentials found in .env.example:"
  grep -inE 'admin123|change-me|CHANGE_ME|password123|directus123' .env.example | sed 's/^/        /'
  ISSUES=$((ISSUES + 1))
else
  echo -e "  ${GREEN}OK${NC}    No default passwords in .env.example"
fi
echo ""

# ── 4. Hardcoded Ports in Compose Files ──────────────────────────────────────
echo -e "${CYAN}[4] Hardcoded Ports in Compose${NC}"

HARDCODED=$(grep -rnE '"[0-9]{4}:[0-9]{4}"' --include='docker-compose.yml' . 2>/dev/null | grep -v '${' | grep -v '.git' || true)
if [ -n "$HARDCODED" ]; then
  echo -e "  ${YELLOW}WARN${NC}  Potential hardcoded port mappings:"
  echo "$HARDCODED" | sed 's/^/        /'
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "  ${GREEN}OK${NC}    No hardcoded port mappings (all use \${VAR})"
fi
echo ""

# ── 5. Missing Health Checks ─────────────────────────────────────────────────
echo -e "${CYAN}[5] Health Checks${NC}"

for f in $(find . -name 'docker-compose.yml' -not -path './.git/*'); do
  SERVICES=$(python3 -c "
import yaml
with open('$f') as fh:
    data = yaml.safe_load(fh)
for name, svc in data.get('services', {}).items():
    has_hc = 'healthcheck' in svc
    print(f'  {\"$f\"}:{name} healthcheck={\"yes\" if has_hc else \"NO\"}')" 2>/dev/null || true)
  echo "$SERVICES"
done
echo ""

# ── 6. Missing Logging Config ────────────────────────────────────────────────
echo -e "${CYAN}[6] Logging Configuration${NC}"

for f in $(find . -name 'docker-compose.yml' -not -path './.git/*'); do
  NO_LOG=$(python3 -c "
import yaml
with open('$f') as fh:
    data = yaml.safe_load(fh)
for name, svc in data.get('services', {}).items():
    if 'logging' not in svc:
        print(f'$f:{name}')" 2>/dev/null || true)
  if [ -n "$NO_LOG" ]; then
    echo -e "  ${YELLOW}WARN${NC}  No logging config on: $NO_LOG" | tr '\n' ' '
    echo ""
    WARNINGS=$((WARNINGS + 1))
  fi
done
echo ""

# ── 7. Missing READMEs ───────────────────────────────────────────────────────
echo -e "${CYAN}[7] README Coverage${NC}"

for dir in optional/*/; do
  if [ ! -f "${dir}README.md" ]; then
    echo -e "  ${YELLOW}WARN${NC}  No README.md in $dir"
    WARNINGS=$((WARNINGS + 1))
  fi
done
for dir in skills/*/; do
  if [ ! -f "${dir}SKILL.md" ]; then
    echo -e "  ${RED}MISS${NC}  No SKILL.md in $dir"
    ISSUES=$((ISSUES + 1))
  fi
done
echo ""

# ── 8. Trigger Command Coverage ──────────────────────────────────────────────
echo -e "${CYAN}[8] Trigger Commands${NC}"

TRIGGERS_IN_AGENTS=$(grep -oE '\`[a-z-]+\`' optional/01-agents-md/AGENTS.template.md 2>/dev/null | tr -d '`' | sort -u || true)
for trigger in $TRIGGERS_IN_AGENTS; do
  FOUND=$(grep -rl "trigger.*$trigger\|$trigger.*trigger" --include='SKILL.md' skills/ optional/ 2>/dev/null | head -1 || true)
  if [ -n "$FOUND" ]; then
    echo -e "  ${GREEN}OK${NC}    '$trigger' → $FOUND"
  else
    echo -e "  ${YELLOW}WARN${NC}  '$trigger' mentioned in AGENTS.md but no SKILL.md defines it"
    WARNINGS=$((WARNINGS + 1))
  fi
done
echo ""

# ── 9. TODO/FIXME Markers ────────────────────────────────────────────────────
echo -e "${CYAN}[9] TODO/FIXME Markers${NC}"

TODOS=$(grep -rn 'TODO\|FIXME\|HACK\|XXX' --include='*.md' --include='*.sh' --include='*.yml' --include='*.ts' --include='*.js' --include='*.astro' . 2>/dev/null | grep -v '.git/' | grep -v node_modules | grep -v 'analyse.sh' | grep -v 'SKILL.md.*grep' || true)
if [ -n "$TODOS" ]; then
  TODO_COUNT=$(echo "$TODOS" | wc -l)
  echo -e "  ${YELLOW}WARN${NC}  $TODO_COUNT TODO/FIXME markers found:"
  echo "$TODOS" | head -10 | sed 's/^/        /'
  [ "$TODO_COUNT" -gt 10 ] && echo "        ... and $((TODO_COUNT - 10)) more"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "  ${GREEN}OK${NC}    No TODO/FIXME markers"
fi
echo ""

# ── 10. Git Status ───────────────────────────────────────────────────────────
echo -e "${CYAN}[10] Git Status${NC}"

UNCOMMITTED=$(git status --short 2>/dev/null | wc -l)
if [ "$UNCOMMITTED" -gt 0 ]; then
  echo -e "  ${YELLOW}WARN${NC}  $UNCOMMITTED uncommitted file(s):"
  git status --short | head -10 | sed 's/^/        /'
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "  ${GREEN}OK${NC}    Working tree clean"
fi
echo ""

# ── Summary ──────────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════"
echo -e "  ${RED}Issues:    $ISSUES${NC}"
echo -e "  ${YELLOW}Warnings:  $WARNINGS${NC}"
echo -e "  ${GREEN}All clear: $([ $ISSUES -eq 0 ] && [ $WARNINGS -eq 0 ] && echo 'YES' || echo 'NO')${NC}"
echo "═══════════════════════════════════════════════════════════"
