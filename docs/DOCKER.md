# Docker Runtime Guide

This project uses a single modular runtime entrypoint.
Primary runtime flow is pulling the published GHCR image.

## Compose Requirements

Use the following mount pattern in [docker-compose.yml](../docker-compose.yml):

```yaml
image: ghcr.io/rizz360/ts-to-mkv:latest
pull_policy: always
volumes:
  - /your/input/path:/input
  - /your/output/path:/output
```

Use the compose `environment` block as the primary runtime config source.
All supported variables with defaults are listed directly in `docker-compose.yml`.

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

If you prefer explicit file sourcing inside the container, set `TS_TO_MKV_CONFIG` to a mounted file path.

## Verify

```bash
docker compose logs -f ts-to-mkv
```

Expected startup message pattern:
- `ts-to-mkv processor starting in [mode] mode...`

## Filename Support

- Paths with spaces, quotes, and UTF-8 characters are supported.
- Paths containing literal newline characters are not supported.

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

If your storage backend does not propagate inotify events reliably, set `MONITOR_MODE=poll` in [docker-compose.yml](../docker-compose.yml).
