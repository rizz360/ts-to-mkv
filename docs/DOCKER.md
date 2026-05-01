# Docker Runtime Guide

This project uses a single modular runtime entrypoint.
Primary runtime flow is pulling the published GHCR image.

## Compose Requirements

Use the following mount pattern in [docker-compose.yml](docker-compose.yml):

```yaml
image: ghcr.io/rizz360/ts-to-mkv:latest
pull_policy: always
volumes:
  - /your/input/path:/input
  - /your/output/path:/output
  - ./config:/config:ro
entrypoint: /app/entrypoint.sh
```

## Start

```bash
docker compose down
docker compose pull
docker compose up -d
```

## Local Development Fallback

If you are changing scripts locally and want live-mounted code, temporarily switch to local build mode:

```yaml
build: .
volumes:
  - ./app:/app
  - ./tests:/tests:ro
```

## Verify

```bash
docker compose logs -f ts-to-mkv
```

Expected startup message pattern:
- `ts-to-mkv processor starting in [mode] mode...`

## Validate in Container

```bash
docker compose exec ts-to-mkv bash /tests/test_safety.sh
docker compose exec ts-to-mkv bash /tests/test_modular.sh
```

## Troubleshooting

### Entrypoint syntax

```bash
docker compose exec ts-to-mkv bash -n /app/entrypoint.sh
```

### Confirm active monitor mode

```bash
docker compose exec ts-to-mkv bash -c 'source /app/lib/config.sh && load_config && echo "$MONITOR_MODE"'
```

If your storage backend does not propagate inotify events reliably, set `MONITOR_MODE=poll` in [config/.env](config/.env).
