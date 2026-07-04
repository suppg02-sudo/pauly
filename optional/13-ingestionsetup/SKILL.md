# Ingestion API Client

Remote client for the ingestion router. When a URL is pasted into chat, call the `/quick` endpoint. The API auto-detects the type (YouTube, GitHub, web, news), applies sensible defaults, generates a blog post with environment analysis, and produces podcast narration — all in one call.

## Connection

Base URL: `http://INGESTION_HOST:8913`

Replace `INGESTION_HOST` with your server's hostname or LAN IP before use.

## Trigger

When invoked, extract the URL from the user's message and POST it to `/quick`. Do not ask for confirmation.

## Quick Submit (Default)

```bash
curl -s -X POST http://INGESTION_HOST:8913/quick \
  -H 'Content-Type: application/json' \
  -d '{"url": "PASTED_URL"}'
```

That's it. The API handles detection, defaults, blog post generation, publishing, and podcast narration.

## Optional Overrides

Only if the user explicitly requests different settings:

```bash
curl -s -X POST http://INGESTION_HOST:8913/quick \
  -H 'Content-Type: application/json' \
  -d '{
    "url": "PASTED_URL",
    "content_type": "breakdown",
    "depth": "deep",
    "diagrams": true,
    "env_analysis": true,
    "voice": "guy",
    "speaking_rate": "normal"
  }'
```

| Param | Options | Default |
|-------|---------|---------|
| `content_type` | story, guide, breakdown, take, reference | auto per URL type |
| `depth` | quick (~700w), standard (~1200w), deep (~1800w) | deep for YouTube/GitHub, standard for web/news |
| `diagrams` | true/false | true for GitHub, false otherwise |
| `env_analysis` | true/false | true for YouTube |
| `voice` | aria, guy, jenny, davis, amanda, ana, christopher, eric | aria |
| `speaking_rate` | slow, normal, fast, very-fast | normal |

## Detect Type Only (If Needed)

```bash
curl -s "http://INGESTION_HOST:8913/detect?url=URL"
```

Returns: `{"input_type": "youtube", "defaults": {...}}`

## Response Handling

The `/quick` response contains:

| Field | Description |
|-------|-------------|
| `job.status` | `completed`, `queued`, or `failed` |
| `job.result.report.phase_details` | Per-phase results (extract, write, publish, etc.) |
| `podcast.audio_url` | MP3 narration URL (if generated) |
| `podcast_error` | Present if narration failed |

### If Completed

Extract the blog URL from `phase_details` where `id == "publish"`, then report:

> Blog post published: http://INGESTION_HOST:3002/posts/slug/
> Podcast: http://INGESTION_HOST:8099/audio/abc123

### If Queued

> Job #{id} queued at position {N}. Poll: `curl http://INGESTION_HOST:8913/jobs/{id}`

Offer to wait:

```bash
curl -s "http://INGESTION_HOST:8913/jobs/{id}?wait=true&timeout=300"
```

### If Failed

> Job failed: {error}. The API may be processing another job — retry in a moment.

## Queue Operations

```bash
# Queue overview
curl -s http://INGESTION_HOST:8913/status | python3 -m json.tool

# Specific job (supports long-poll)
curl -s "http://INGESTION_HOST:8913/jobs/5?wait=true&timeout=300"

# Recent history
curl -s http://INGESTION_HOST:8913/history | python3 -m json.tool

# Cancel pending job
curl -X DELETE http://INGESTION_HOST:8913/jobs/5

# Clear stuck lock
curl -X POST http://INGESTION_HOST:8913/clear-lock

# Prune old jobs
curl -X POST http://INGESTION_HOST:8913/prune -H 'Content-Type: application/json' -d '{"days": 7}'
```

## URL Type Detection Rules

The API uses these patterns to auto-classify pasted URLs:

| URL Pattern | Detected Type | Default Type | Default Depth | Env Analysis |
|-------------|--------------|-------------|---------------|-------------|
| `youtube.com/watch` | youtube | story | deep | yes |
| `youtu.be/` | youtube | story | deep | yes |
| `youtube.com/shorts/` | youtube | story | deep | yes |
| `github.com/owner/repo` | github | breakdown | deep | — |
| `bbc.co.uk`, `theguardian.com` | news | take | standard | — |
| `tesco.com`, `asda.com` | shop | — | — | — |
| any other `https://` | web-url | take | standard | — |

## What the API Does Behind the Scenes

1. Detects URL type via regex
2. Applies default content type and depth for that type
3. Runs the blog-post flow: extract transcript/content → validate → scan for GitHub projects → analyse against environment → write → publish to blog → notify via Telegram
4. Extracts the published blog post URL from the job result
5. Calls Podcastfy (`/narrate`) to generate single-narrator audio
6. Returns job result + podcast audio URL

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Connection refused` | API server not running — check `systemctl status ingestion-api` on the server |
| `502 Bad Gateway` | CLI error — check `/var/log/ingestion-api.log` on the server |
| `504 Gateway Timeout` | Job took too long — increase `timeout` param or use async mode (omit `wait`) |
| Blog URL missing in response | Phase engine may not have published — check `job.result.report.phase_details` for errors |
| Podcast failed | Podcastfy service may be down — check `http://INGESTION_HOST:8099/health` |
| Queue stuck | Clear lock: `curl -X POST http://INGESTION_HOST:8913/clear-lock` |
