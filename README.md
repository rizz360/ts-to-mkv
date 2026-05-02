# ts-to-mkv 🧼📺

[![CI](https://github.com/rizz360/ts-to-mkv/actions/workflows/ci.yml/badge.svg)](https://github.com/rizz360/ts-to-mkv/actions/workflows/ci.yml)
[![Release](https://github.com/rizz360/ts-to-mkv/actions/workflows/release.yml/badge.svg)](https://github.com/rizz360/ts-to-mkv/actions/workflows/release.yml)

A Docker-based tool that converts `.ts` recordings to `.mkv`, preserves folder structure, and applies smart remux/encode decisions with hardware fallback.

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
   - environment defaults grouped by category
2. Adjust environment values directly in [docker-compose.yml](docker-compose.yml)
3. Start:

```bash
docker compose pull
docker compose up -d
```

## Configuration

Primary runtime config source: [docker-compose.yml](docker-compose.yml) under `environment`.

Optional: mount and set `TS_TO_MKV_CONFIG` (or `CONFIG_FILE`) if you still want file-based config.

Important knobs:
- `MONITOR_MODE` (`watch`, `poll`, `once`)
- `VIDEO_CODEC` / `FALLBACK_CODEC`
- `USE_CRF`, `CRF_*`, `BITRATE_*`
- `ENABLE_PARALLEL_PROCESSING`, `MAX_CONCURRENT_JOBS`
- `FORCE_ENCODE_SD`, `SKIP_ALREADY_HEVC`

Filename support note:
- Paths with spaces, quotes, and UTF-8 characters are supported.
- Paths containing literal newline characters are not supported.

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
