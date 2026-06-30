# Workflows

## Deploy Workflow

```
1. source .env
2. cd directus && docker compose up -d
3. sleep 10 && curl http://localhost:${PORT_DIRECTUS}/server/health
4. cd ../astro-docs && docker compose up -d
5. curl -o /dev/null -w "%{http_code}" http://localhost:${PORT_ASTRO}/
```

## Publish Content Workflow

```
1. source .env
2. POST to Directus API with title, slug, content, date_published
3. Verify: curl http://localhost:${PORT_ASTRO}/docs/{slug}/
```

## Update Workflow

```
1. source .env
2. cd directus && docker compose pull && docker compose up -d
3. cd ../astro-docs && docker compose build --no-cache && docker compose up -d
4. Verify health on both
```

## Backup Workflow

```
1. source .env
2. docker exec directus-postgres pg_dump -U directus directus > backup.sql
3. (optional) upload to remote storage
```

## Troubleshooting Workflow

```
1. Check health: curl http://localhost:${PORT_DIRECTUS}/server/health
2. Check containers: docker ps | grep -E 'directus|astro'
3. Check logs: docker logs <container> --tail 50
4. Check network: docker network inspect ${DOCKER_NETWORK}
5. Restart if needed: docker compose restart
```
