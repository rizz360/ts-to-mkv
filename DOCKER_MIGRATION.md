# Docker Runtime Guide

This project uses a single modular runtime entrypoint.

## Compose Requirements

Use the following mount pattern in [docker-compose.yml](docker-compose.yml):

```yaml
volumes:
  - /your/input/path:/input
  - /your/output/path:/output
  - ./config:/config:ro
  - ./app:/app
entrypoint: /app/entrypoint.sh
```

## Start

```bash
docker compose down
docker compose up --build
```

## Verify

```bash
docker compose logs -f ts-cleanup
```

Expected startup message pattern:
- `TS-to-MKV processor starting in [mode] mode...`

## Validate in Container

```bash
docker compose exec ts-cleanup bash /tests/test_safety.sh
docker compose exec ts-cleanup bash /tests/test_modular.sh
```

## Troubleshooting

### Entrypoint syntax

```bash
docker compose exec ts-cleanup bash -n /app/entrypoint.sh
```

### Confirm active monitor mode

```bash
docker compose exec ts-cleanup bash -c 'source /app/lib/config.sh && load_config && echo "$MONITOR_MODE"'
```

If your storage backend does not propagate inotify events reliably, set `MONITOR_MODE=poll` in [config/cleanup.env](config/cleanup.env).
