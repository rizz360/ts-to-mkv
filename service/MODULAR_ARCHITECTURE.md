# TS-to-MKV Modular Architecture

This repository uses a modular shell architecture with a single runtime entrypoint.

## Structure

```
service/
├── cleanup_modular.sh      # Main orchestrator script
├── cleanup.env             # Runtime configuration
├── test_modular.sh         # Module-level validation
├── test_safety.sh          # Safety and regression checks
└── lib/
    ├── system.sh           # Error handling, dependency checks, init
    ├── logging.sh          # Logging and ntfy notifications
    ├── config.sh           # Config loading and validation
    ├── video_analysis.sh   # ffprobe metadata and decisions
    ├── encoding.sh         # Encode/remux operations
    ├── file_processor.sh   # Per-file processing workflow
    └── file_monitor.sh     # Existing/new file discovery
```

## Entry Flow

1. `cleanup_modular.sh` sources all modules.
2. `setup_signal_handlers` installs graceful shutdown traps.
3. `load_config` and `validate_config` load and validate env.
4. `check_dependencies` verifies required tools.
5. `process_existing_files` handles backlog.
6. Runtime continues in selected monitor mode:
   - `once`
   - `watch`
   - `poll`

## Module Contracts

- `file_processor.sh` returns explicit status from `process_file`.
- `file_monitor.sh` only marks poll-cache entries when processing succeeds.
- Monitoring and parallel loops avoid strict-mode arithmetic/pipeline traps.

## Validation Strategy

- `test_modular.sh` validates module presence, function loading, and syntax.
- `test_safety.sh` enforces modular-only invariants and regression guardrails.

Run both checks with:

```bash
bash /service/test_modular.sh
bash /service/test_safety.sh
```
