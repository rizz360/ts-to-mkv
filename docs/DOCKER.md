# Docker Runtime Guide

This project uses a single modular runtime entrypoint.

## Compose Requirements

Use the following mount pattern in [docker-compose.yml](../docker-compose.yml):

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
docker compose logs -f ts-to-mkv
```

Expected startup message pattern:
- `ts-to-mkv processor starting in [mode] mode...`

## Validate

Run these checks from the repository root on the host (or in CI), not inside the runtime container. They validate repository files such as `docker-compose.yml`, `README.md`, and `docs/DOCKER.md`, which are not mounted by the compose setup shown above.

```bash
bash tests/test_safety.sh
bash tests/test_modular.sh
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

If your storage backend does not propagate inotify events reliably, set `MONITOR_MODE=poll` in [config/.env](../config/.env).
