## URL Auto-Ingestion (MANDATORY)

- When a URL (`https://`, `youtu.be/`, `youtube.com/`, `github.com/owner/repo`) is pasted into chat, you MUST immediately load and follow the ingestion-api skill at `~/.config/opencode/skills/ingestion-api/SKILL.md`
- Do NOT ask what to do with the URL — load the skill and call the API automatically
- Do NOT show a menu — the API handles type detection and flow selection
- Report the result (blog URL + podcast audio URL) when the API responds
