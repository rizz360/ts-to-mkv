# Modular Script Architecture

This document describes the refactored modular architecture for the TS-to-MKV processor.

## Overview

The original monolithic `cleanup.sh` script (560+ lines) has been refactored into a modular architecture with clear separation of concerns. This improves maintainability, testability, and readability.

## File Structure

```
service/
├── cleanup.sh              # Original monolithic script (preserved for comparison)
├── cleanup_modular.sh      # New main orchestrator script
├── cleanup.env             # Configuration file (unchanged)
└── lib/                    # Module library
    ├── config.sh           # Configuration management
    ├── logging.sh           # Logging and notifications
    ├── video_analysis.sh    # Video metadata and analysis
    ├── encoding.sh          # Video encoding and remuxing
    ├── file_processor.sh    # File processing workflow
    ├── file_monitor.sh      # File monitoring and discovery
    └── system.sh            # System utilities and initialization
```

## Module Responsibilities

### `system.sh` - System Utilities (40 lines)
- Error handling setup (`set -euo pipefail`)
- Signal handlers for graceful shutdown
- Dependency checking (ffmpeg, ffprobe, jq)
- Directory initialization

### `logging.sh` - Logging & Notifications (35 lines)
- Standardized logging functions (info, warn, error)
- Ntfy push notifications
- Log directory initialization
- Processing statistics

### `config.sh` - Configuration Management (75 lines)
- Environment variable loading from cleanup.env
- Default value assignment
- Configuration validation
- Configuration summary display

### `video_analysis.sh` - Video Analysis (85 lines)
- Video metadata extraction using ffprobe
- Resolution and codec detection
- Encoding decision logic
- Output validation

### `encoding.sh` - Video Processing (110 lines)
- Encoding parameter calculation
- Remuxing operations
- Multi-codec encoding with fallback
- FFmpeg command construction

### `file_processor.sh` - File Processing Workflow (130 lines)
- Individual file processing pipeline
- Temporary file management
- Success/failure handling
- Sequential and parallel processing modes

### `file_monitor.sh` - File Monitoring (85 lines)
- Existing file discovery and queuing
- Real-time file system monitoring (inotify)
- Periodic polling mode
- New file detection and processing

### `cleanup_modular.sh` - Main Orchestrator (45 lines)
- Module loading and initialization
- Main program flow coordination
- Mode selection (once/watch/poll)

## Benefits of Modular Architecture

### 1. **Maintainability**
- Each module has a single, clear responsibility
- Easier to locate and fix bugs
- Simpler to understand individual components
- Reduced cognitive load when making changes

### 2. **Testability**
- Individual modules can be tested in isolation
- Mock dependencies for unit testing
- Easier to write focused test cases

### 3. **Reusability**
- Modules can be reused across different scripts
- Common functionality (logging, config) is centralized
- Easier to extend functionality

### 4. **Readability**
- Much shorter files (35-130 lines vs 560+ lines)
- Clear naming conventions
- Logical grouping of related functions

### 5. **Flexibility**
- Easy to swap out implementations (e.g., different monitoring strategies)
- Simple to add new features without touching existing code
- Configuration changes isolated to one module

## Migration Guide

### Switching to Modular Version

1. **Test the modular version:**
   ```bash
   # Make the new script executable
   chmod +x /service/cleanup_modular.sh
   
   # Test with existing configuration
   docker-compose exec ts-to-mkv /service/cleanup_modular.sh
   ```

2. **Update docker-compose.yml to use new script:**
   ```yaml
   command: ["/service/cleanup_modular.sh"]
   ```

3. **Verify functionality:**
   - Check logs are generated correctly
   - Verify file processing works as expected
   - Test different monitor modes

### Backwards Compatibility

- The original `cleanup.sh` remains unchanged
- All configuration in `cleanup.env` is fully compatible
- Same Docker environment and dependencies
- Identical functionality and behavior

## Development Workflow

### Adding New Features

1. **Identify the appropriate module** based on the feature's responsibility
2. **Add functions to the relevant module** (or create a new module if needed)
3. **Update the main script** to call new functionality if needed
4. **Test the specific module** independently

### Example: Adding a new video codec

1. **Update `encoding.sh`** to add codec-specific logic
2. **Update `config.sh`** to add new configuration options
3. **Test encoding functions** with the new codec

### Debugging

1. **Enable verbose logging** by modifying the specific module
2. **Test individual modules** by sourcing them in isolation
3. **Use module-specific log files** for targeted debugging

## Performance Considerations

### Memory Usage
- Modular design has minimal memory overhead
- Each module is loaded once at startup
- No significant performance impact

### Execution Speed
- Marginal overhead from module loading (~1-2ms)
- Identical processing performance
- Same parallel processing capabilities

### File Size
- Total modular code: ~605 lines across 8 files
- Original monolithic: 560+ lines in 1 file
- Slight increase due to module headers and documentation

## Best Practices

### Module Design
- Keep modules focused on a single responsibility
- Minimize dependencies between modules
- Use clear, descriptive function names
- Include comments for complex logic

### Error Handling
- Each module should handle its own errors appropriately
- Use consistent error reporting via logging functions
- Fail fast for configuration errors
- Graceful degradation for processing errors

### Configuration
- All user-configurable options remain in `cleanup.env`
- Module-specific constants can be defined in modules
- Validate configuration early in the startup process

## Future Enhancements

The modular architecture makes several enhancements easier to implement:

1. **Unit Testing Framework** - Test individual modules
2. **Alternative Monitoring Backends** - Add support for other file system events
3. **Plugin System** - Load additional processing modules dynamically
4. **Configuration Management** - Support for multiple configuration files
5. **Advanced Encoding Profiles** - Codec-specific optimization modules
6. **Monitoring Dashboard** - Separate monitoring from processing logic

## Conclusion

The modular refactoring provides significant benefits in maintainability, testability, and extensibility while preserving full backwards compatibility. The new architecture is easier to understand, modify, and extend, making it much more suitable for long-term maintenance and enhancement.
