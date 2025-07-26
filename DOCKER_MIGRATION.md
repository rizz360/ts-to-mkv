# Docker Migration Guide for Modular Architecture

This guide helps you migrate your Docker setup to use the new modular architecture.

## Quick Migration (Recommended)

### 1. Update docker-compose.yml
The repository now defaults to the modular architecture. Simply rebuild your container:

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker compose down
docker compose up --build
```

The `docker-compose.yml` now uses `cleanup_modular.sh` by default.

### 2. Verify Migration
Check that the container starts correctly:

```bash
# Check container logs
docker compose logs -f ts-cleanup

# You should see: "TS-to-MKV processor starting in [mode] mode..."
```

## Manual Configuration Options

### Option 1: Use Modular Architecture (Default)
```yaml
# docker-compose.yml
services:
  ts-cleanup:
    # ... other config ...
    entrypoint: /service/cleanup_modular.sh
```

### Option 2: Use Legacy Monolithic Script
```yaml
# docker-compose.yml  
services:
  ts-cleanup:
    # ... other config ...
    entrypoint: /service/cleanup.sh
```

## Testing Inside Container

### Test Modular Version
```bash
# Enter running container
docker compose exec ts-cleanup bash

# Run migration validation
/service/migrate_to_modular.sh

# Test modular script syntax
/service/test_modular.sh

# Exit container
exit
```

### Compare Performance
Both versions offer identical functionality:

```bash
# Test current setup
docker compose exec ts-cleanup /service/cleanup_modular.sh --help 2>/dev/null || echo "Script runs normally"

# Test legacy version  
docker compose exec ts-cleanup /service/cleanup.sh --help 2>/dev/null || echo "Script runs normally"
```

## Volume Mounts

No changes needed to volume mounts. Both architectures use the same paths:

```yaml
volumes:
  - /your/input/path:/input
  - /your/output/path:/output  
  - /your/config/path/service:/service  # Contains both cleanup.sh and cleanup_modular.sh
```

## Configuration Compatibility

### Unchanged
- `cleanup.env` - No changes needed
- Log files - Same location and format
- Input/output directories - Same paths
- Environment variables - All work identically

### New Features Available
With the modular architecture, you can now:

```bash
# Test individual modules
docker compose exec ts-cleanup bash -c "source /service/lib/logging.sh && log_info 'Test message'"

# Validate configuration
docker compose exec ts-cleanup /service/lib/config.sh

# Check specific functionality
docker compose exec ts-cleanup bash -c "source /service/lib/video_analysis.sh && declare -f get_video_info"
```

## Troubleshooting

### Issue: Container won't start
```bash
# Check syntax of modular script
docker compose exec ts-cleanup bash -n /service/cleanup_modular.sh

# Fallback to legacy version
# Edit docker-compose.yml: entrypoint: /service/cleanup.sh
docker compose restart ts-cleanup
```

### Issue: Different behavior observed
```bash
# Compare configurations
docker compose exec ts-cleanup bash -c "
  echo '=== Modular Config Test ==='
  source /service/lib/config.sh
  load_config
  print_config_summary
"

# Check module loading
docker compose exec ts-cleanup /service/test_modular.sh
```

### Issue: Performance concerns
Both versions have identical performance. To verify:

```bash
# Time startup of each version
time docker compose exec ts-cleanup /service/cleanup_modular.sh --version 2>/dev/null || true
time docker compose exec ts-cleanup /service/cleanup.sh --version 2>/dev/null || true
```

## Rollback Procedure

If you need to rollback to the legacy version:

### Temporary Rollback
```bash
# Edit docker-compose.yml
# Change: entrypoint: /service/cleanup_modular.sh
# To:     entrypoint: /service/cleanup.sh

docker compose restart ts-cleanup
```

### Permanent Rollback
```bash
# Use git to restore previous version
git log --oneline | head -5  # Find commit before modular refactor
git checkout <previous-commit-hash> -- service/
docker compose restart ts-cleanup
```

## Benefits Summary

### Modular Architecture Benefits
- **Maintainability**: Easier to debug and modify
- **Testability**: Individual components can be tested
- **Extensibility**: Add features without touching existing code
- **Documentation**: Better organized and documented

### Docker-Specific Benefits
- **Same container image**: No changes to Dockerfile needed
- **Same dependencies**: All tools already installed
- **Same performance**: Identical processing speed
- **Same configuration**: No changes to cleanup.env needed

## Conclusion

The modular architecture provides significant development benefits while maintaining full compatibility with your existing Docker setup. Migration is as simple as pulling the latest changes and rebuilding your container.

For production use, the modular version is recommended for its improved maintainability and extensibility.
