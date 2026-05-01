# Docker Runtime Guide (Modular-Only)

This project now runs a single supported runtime: modular architecture via `cleanup_modular.sh`.

## Quick Start

```bash
git pull origin main
docker compose down
docker compose up --build
```

The compose service should start with:

```yaml
entrypoint: /service/cleanup_modular.sh
```

## Verify Startup

```bash
docker compose logs -f ts-cleanup
```

Expected log pattern:
- `TS-to-MKV processor starting in [mode] mode...`

## Required Mounts

```yaml
volumes:
  - /your/input/path:/input
  - /your/output/path:/output
  - /your/config/path/service:/service
```

## Validate Inside Container

```bash
docker compose exec ts-cleanup bash
/service/test_modular.sh
/service/test_safety.sh
exit
```

## Troubleshooting

### Container does not start

```bash
docker compose exec ts-cleanup bash -n /service/cleanup_modular.sh
```

### Watch mode does not process new files

```bash
docker compose exec ts-cleanup bash -c 'source /service/lib/config.sh && load_config && echo "$MONITOR_MODE"'
```

If your storage backend does not emit inotify events reliably, set `MONITOR_MODE=poll` in `service/cleanup.env`.

### Verify configuration load

```bash
docker compose exec ts-cleanup bash -c '
  source /service/lib/logging.sh
  source /service/lib/config.sh
  load_config
  print_config_summary
'
```

## Notes

- There is no legacy runtime path in this repository anymore.
- Safety checks are part of the standard validation flow through `test_safety.sh`.
