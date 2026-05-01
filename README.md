# ts-to-mkv 🧼📺

[![CI](https://github.com/rizz360/ts-to-mkv/actions/workflows/ci.yml/badge.svg)](https://github.com/rizz360/ts-to-mkv/actions/workflows/ci.yml)
[![Release](https://github.com/rizz360/ts-to-mkv/actions/workflows/release.yml/badge.svg)](https://github.com/rizz360/ts-to-mkv/actions/workflows/release.yml)

A modular Docker-based tool that converts `.ts` recordings to `.mkv`, preserves folder structure, and applies smart remux/encode decisions with hardware fallback.

## Project Layout

```text
ts-to-mkv/
├── app/
│   ├── entrypoint.sh
│   ├── lib/
│   │   ├── system.sh
│   │   ├── logging.sh
│   │   ├── config.sh
│   │   ├── video_analysis.sh
│   │   ├── encoding.sh
│   │   ├── file_processor.sh
│   │   └── file_monitor.sh
│   └── logs/                  # runtime logs (created automatically)
├── config/
│   └── .env
├── tests/
│   ├── test_modular.sh
│   └── test_safety.sh
├── docs/
│   ├── ARCHITECTURE.md
│   └── REFACTORING_SUMMARY.md
├── .github/workflows/
│   ├── ci.yml
│   └── release.yml
├── docker-compose.yml
├── Dockerfile
└── docs/DOCKER.md
```

## Features

- Continuous file monitoring (`watch`, `poll`, `once`)
- Resolution-aware encode parameters
- QSV-first encoding with fallback codec support
- SD force-encode and HEVC skip logic
- Remux fallback without subtitles when needed
- Parallel processing support
- Ntfy notifications
- Safety and regression checks via dedicated test scripts

## Docker Setup

1. Configure [docker-compose.yml](docker-compose.yml):
   - image pull from GHCR (default)
   - input and output host mounts
   - env_file: ./config/.env
2. Edit [config/.env](config/.env) and optionally override values in compose environment
3. Start:

```bash
docker compose pull
docker compose up -d
```

Entrypoint is modular-only:

```yaml
entrypoint: /app/entrypoint.sh
```

Local build fallback (for development):

```bash
docker compose up --build
```

## Configuration

Primary runtime config source: [config/.env](config/.env) via compose env_file.

Override any value per deployment in [docker-compose.yml](docker-compose.yml) under environment.
Compose environment values take precedence over env_file values.

Important knobs:
- `MONITOR_MODE` (`watch`, `poll`, `once`)
- `VIDEO_CODEC` / `FALLBACK_CODEC`
- `USE_CRF`, `CRF_*`, `BITRATE_*`
- `ENABLE_PARALLEL_PROCESSING`, `MAX_CONCURRENT_JOBS`
- `FORCE_ENCODE_SD`, `SKIP_ALREADY_HEVC`

## Contributing

Contributor setup, local validation commands, commit conventions, and release flow are documented in [CONTRIBUTING.md](CONTRIBUTING.md).

## Logs

Runtime logs are written under [app/logs](app/logs):
- `queue.log`
- `current.log`
- `done.log`
- `error.log`
- `ffmpeg_*.log`

## Additional Docs

- [docs/DOCKER.md](docs/DOCKER.md)
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [docs/REFACTORING_SUMMARY.md](docs/REFACTORING_SUMMARY.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)
