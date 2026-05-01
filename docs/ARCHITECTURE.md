# Architecture

## Runtime Entry

- `/app/entrypoint.sh`

The entrypoint loads module files from `/app/lib` and coordinates startup, config loading, dependency checks, processing, and monitoring mode loops.

## Modules

- `system.sh`: strict mode, signal handling, dependency checks
- `logging.sh`: logging and notifications
- `config.sh`: config loading/defaults/validation
- `video_analysis.sh`: ffprobe metadata extraction and decision support
- `encoding.sh`: remux/encode execution and codec fallback
- `file_processor.sh`: per-file processing flow and parallel worker management
- `file_monitor.sh`: existing/new file discovery in watch/poll/once modes

## Config and Paths

- Config: `/config/cleanup.env` (default)
- Input: `/input`
- Output: `/output`
- Logs: `/app/logs`

`config.sh` supports overriding config path via `TS_TO_MKV_CONFIG`.

## Test Layers

- [tests/test_safety.sh](../tests/test_safety.sh): structural and safety guardrails
- [tests/test_modular.sh](../tests/test_modular.sh): module loading, function availability, syntax, safety invocation
