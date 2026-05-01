# ts-to-mkv 🧼📺

A smart, automated `.ts` cleaner and shrinker for Plex DVR recordings.

This Docker-based tool converts `.ts` files to smaller `.mkv` containers, keeping **all audio/subtitle streams**, adding a `.TV.{resolution}.mkv` suffix, and optionally deleting the originals. Ideal for archival and cleanup tasks after long-term DVR usage.

---

## 🏗️ Modular Architecture

The tool features a modular architecture that improves maintainability and extensibility:

### Architecture Benefits
- **Maintainable**: 7 focused modules (40-155 lines each) vs monolithic script
- **Testable**: Individual components can be tested in isolation
- **Extensible**: Easy to add new features without touching existing code
- **Readable**: Clear separation of concerns and module boundaries

### Migration Options
The tool includes both architectures for flexibility:

#### Option 1: Modular (Recommended)
```yaml
# docker-compose.yml
entrypoint: /service/cleanup_modular.sh
```

#### Option 2: Legacy Monolithic  
```yaml
# docker-compose.yml  
entrypoint: /service/cleanup.sh
```

### Migration Tools
- `migrate_to_modular.sh` - Automated migration helper with validation
- `test_modular.sh` - Comprehensive testing and validation
- Full documentation in `MODULAR_ARCHITECTURE.md`
- Docker-specific guide in `DOCKER_MIGRATION.md`

Both versions offer identical functionality - choose based on your maintenance preferences.

---

## 🔄 Monitoring Modes

---

## ✅ Features

- 🧼 **Modular architecture** - Maintainable, testable design with focused modules
- 🔁 **Continuously monitors** for new `.ts` files or runs once/periodically
- 🗂 **Preserves subfolder structure** in `/output`
- 🧠 Adds `.TV.720p.mkv`, `.TV.480i.mkv`, etc. suffixes based on resolution and scan type
- ⚡ **Uses Intel QSV (Quick Sync Video)** hardware acceleration if available
- 📼 **Resolution-adaptive encoding** - optimized bitrates and presets for each resolution
- 🎯 **Smart content analysis** - automatically chooses between remux and re-encode based on content
- 🔄 **Smart remux fallback** - retries without subtitles if initial remux fails
- ⚙️ **CRF quality mode** - option for better quality/size ratio than fixed bitrate
- 🚀 **Optional parallel processing** - configurable concurrent encoding jobs
- 🎚 Fully configurable via `.env` file
- 🧹 Optionally deletes `.ts` files after successful processing
- 📋 Comprehensive logging: queue, current, done, failed
- 📱 **Push notifications** via Ntfy (optional)
- 📊 **File size reduction tracking** with percentage savings
- ✅ **Enhanced duration validation** with resolution-aware tolerances
- 🧠 **HEVC skip optimization** - avoids re-encoding already efficient files

---

## 🔎 Logs and Monitoring

```
ts-to-mkv/
├── docker-compose.yml
├── Dockerfile
├── service/
│   ├── cleanup.env
│   ├── cleanup.sh              # Original monolithic script (preserved)
│   ├── cleanup_modular.sh      # New modular main script
│   ├── lib/                    # Modular architecture
│   │   ├── system.sh           # System utilities
│   │   ├── logging.sh          # Logging & notifications  
│   │   ├── config.sh           # Configuration management
│   │   ├── video_analysis.sh   # Video analysis
│   │   ├── encoding.sh         # Encoding operations
│   │   ├── file_processor.sh   # File processing
│   │   └── file_monitor.sh     # File monitoring
│   ├── migrate_to_modular.sh   # Migration helper
│   ├── test_modular.sh         # Validation script
│   └── logs/                   # Created automatically at runtime
```

---

## 📋 Requirements

- **Hardware**: Intel CPU with Quick Sync Video support (or compatible GPU for hardware acceleration)
- **Device Access**: `/dev/dri` device mapping for hardware acceleration
- **Base Image**: Uses `akashisn/ffmpeg:7.0.2` with pre-installed FFmpeg 7.0.2
- **Dependencies**: Automatically installed - `curl`, `jq`, `sudo`

---

## 🚀 Setup

### 1. Mount your input/output folders

Edit `docker-compose.yml`:

```yaml
volumes:
  - /mnt/hjem_nas_media/Movies:/input
  - /mnt/hjem_nas_media/Movies-clean:/output
  - /home/qsv/docker-compose/ts-to-mkv/service:/service
```

### 2. Configure behavior

Edit `service/cleanup.env`:

```bash
DELETE_TS=true                      # Delete .ts files after success
REMUX_SIZE_GB=3                     # Files larger than this will be re-encoded (HD content only)
REMUX_FALLBACK_NO_SUBTITLES=true    # Retry remux without subtitles if failed

# --- Processing Mode ---
MONITOR_MODE=watch                  # 'watch' for real-time monitoring, 'poll' for periodic, 'once' for single run
POLL_INTERVAL=300                   # Seconds between scans when using poll mode (5 minutes)

# --- Processing Settings ---
ENABLE_PARALLEL_PROCESSING=false    # Enable parallel processing (true/false)
MAX_CONCURRENT_JOBS=2               # Number of concurrent encoding jobs
FORCE_ENCODE_SD=true                # Always encode SD content (576p/i, 480p/i) for better compression

# --- Encoding Settings ---
VIDEO_CODEC=hevc_qsv                # Primary video codec (hevc_qsv, libx265, libx264)
FALLBACK_CODEC=libx265              # Fallback codec if hardware encoding fails
AUDIO_CODEC=copy                    # Copy all audio streams

# --- Resolution-specific Bitrates ---
BITRATE_1080=4000k                  # 1080p/1080i bitrate
BITRATE_720=2500k                   # 720p/720i bitrate  
BITRATE_576=1500k                   # 576p/576i bitrate
BITRATE_480=1200k                   # 480p/480i bitrate
BITRATE_DEFAULT=2000k               # Fallback bitrate

# --- Quality-based Encoding (CRF) ---
USE_CRF=false                       # Use Constant Rate Factor (recommended)
CRF_1080=23                         # 1080p/1080i CRF value (lower = higher quality)
CRF_720=24                          # 720p/720i CRF value
CRF_576=26                          # 576p/576i CRF value  
CRF_480=28                          # 480p/480i CRF value

# --- Resolution-specific Presets ---
PRESET_HD=fast                      # Preset for HD content (720p+)
PRESET_SD=medium                    # Preset for SD content (slower but better compression)

# --- Advanced Settings ---
SKIP_ALREADY_HEVC=true              # Skip files already encoded with HEVC at reasonable bitrate

# --- Notifications ---
NTFY_URL=http://192.168.1.119:1888/ts-to-mkv  # Optional: ntfy endpoint
```

### 3. Launch the container

```bash
docker compose up --build
```

**Note**: The current `docker-compose.yml` in this repository uses the legacy monolithic script (`cleanup.sh`) by default. To use the modular architecture, change the entrypoint to `/service/cleanup_modular.sh`.

---

## 📱 Notifications (Optional)

The tool can send push notifications via Ntfy when processing completes:

1. Set up an Ntfy server or use a public instance
2. Configure `NTFY_URL` in `service/cleanup.env`
3. Notifications include:
   - Processing start/completion with batch summary
   - File size reduction statistics
   - Individual file completion status

Example notification: `"movie.TV.1080i.mkv - Size reduced from 2500MB to 800MB (68% reduction)"`

---

## � Monitoring Modes

The tool supports three different monitoring modes:

### Watch Mode (Default - Recommended)
```bash
MONITOR_MODE=watch
```
- **Real-time file monitoring** using inotify events
- **Immediate processing** when new `.ts` files are detected
- **Most efficient** - no CPU overhead when idle
- **Best for**: Active recording scenarios, minimal resource usage

### Poll Mode
```bash
MONITOR_MODE=poll
POLL_INTERVAL=300    # Check every 5 minutes
```
- **Periodic scanning** of the input directory
- **Configurable interval** between scans
- **Compatibility** - works on all file systems
- **Best for**: Network storage, compatibility requirements

### Once Mode
```bash
MONITOR_MODE=once
```
- **Single run** - processes existing files and exits
- **Legacy behavior** - compatible with external scheduling
- **Best for**: Cron jobs, manual processing

---

The tool automatically creates `service/logs/` directory with detailed logging:

| File              | Purpose                            |
| ----------------- | ---------------------------------- |
| `queue.log`       | List of `.ts` files to process     |
| `current.log`     | Currently processed file           |
| `done.log`        | Successfully converted files       |
| `error.log`       | Failed files with error details    |
| `ffmpeg_*.log`    | Individual FFmpeg encoding logs    |

Example:

```bash
tail -f service/logs/current.log
cat service/logs/done.log
```

---

## 🧠 Examples

| Input File           | Resolution | Output File                   | Expected Compression |
| -------------------- | ---------- | ----------------------------- | -------------------- |
| `Show1/ep1.ts`       | 720p       | `Show1/ep1.TV.720p.mkv`       | ~75% reduction       |
| `Movie/recording.ts` | 576i       | `Movie/recording.TV.576i.mkv` | ~40% reduction       |
| `Event/2024.ts`      | 1080i      | `Event/2024.TV.1080i.mkv`     | ~65% reduction       |
| `Sports/game.ts`     | 480i       | `Sports/game.TV.480i.mkv`     | ~50% reduction       |

---

## 💡 Optimization Features

### Resolution-Adaptive Processing
- **720p+ (HD)**: Uses `fast` preset with higher bitrates for quality preservation
- **576p/480p (SD)**: Uses `medium` preset with optimized compression for better size reduction
- **Interlaced content**: Handled identically to progressive at same resolution

### Smart Processing Logic
- **SD Content**: Always encoded for maximum compression (configurable)
- **HD Content**: Remuxed if ≤3GB, encoded if larger
- **HEVC Skip**: Avoids re-encoding already efficient HEVC files
- **Content Analysis**: Examines existing codec and bitrate before processing

### Quality Modes
- **Bitrate Mode**: Fixed bitrates optimized per resolution
- **CRF Mode**: Variable bitrate for better quality/size balance
- **Preset Optimization**: Different encoding speeds based on content type

### Performance Options
- **Sequential Processing**: Default, processes one file at a time
- **Parallel Processing**: Optional, configurable concurrent jobs
- **Hardware Acceleration**: Intel QSV for faster encoding
- **Codec Fallback**: Automatic fallback to software encoding if hardware fails

### Codec Compatibility
- **Primary Codec**: Attempts hardware encoding first (hevc_qsv recommended)
- **Fallback Codec**: Software encoding if hardware fails (libx265 recommended)
- **Error Handling**: Automatic retry with different codec parameters
- **Compatibility**: Works on systems with or without hardware acceleration

---

## 📊 Expected Performance

Based on typical broadcast content:

| Resolution | Before Optimization | After Optimization | Improvement |
|------------|--------------------|--------------------|-------------|
| 720p       | ~75% reduction     | ~75% reduction     | Maintained quality |
| 576p/576i  | 5-15% reduction    | 30-50% reduction   | 3-5x better |
| 480p/480i  | 5-15% reduction    | 40-55% reduction   | 4-6x better |

Processing speed improvements: 20-40% faster with optimized parameters.

---

## 🔧 Advanced Configuration

### CRF vs Bitrate Mode

**CRF Mode (Recommended)**:
```bash
USE_CRF=true
CRF_720=24    # Lower = higher quality, larger files
```

**Bitrate Mode**:
```bash
USE_CRF=false
BITRATE_720=2500k    # Fixed bitrate regardless of content complexity
```

### Parallel Processing

For systems with multiple CPU cores:
```bash
ENABLE_PARALLEL_PROCESSING=true
MAX_CONCURRENT_JOBS=3    # Adjust based on CPU/storage capability
```

### Content-Specific Optimization

Force encoding of SD content for better compression:
```bash
FORCE_ENCODE_SD=true     # Always encode 576p/480p content
REMUX_SIZE_GB=3         # Only affects HD content threshold
```

---

## 💡 Tips

* **Modular architecture**: Use `cleanup_modular.sh` for easier maintenance and debugging
* **Migration helper**: Run `migrate_to_modular.sh` for seamless transition validation
* **Continuous monitoring**: Default `watch` mode provides real-time processing of new files
* **Smart file detection**: Handles various file operations (copy, move, create)
* Uses `ffprobe` to automatically analyze resolution, codec, and content characteristics
* Leaves all non-`.ts` files untouched
* **Resolution-aware processing**: Different strategies for HD vs SD content
* **Fallback handling**: If remux fails due to subtitle compatibility, automatically retries without subtitles
* **Quality assurance**: Validates encoded file duration with resolution-specific tolerances
* **Hardware optimization**: Leverages Intel QSV for efficient H.265 encoding
* **Smart skip**: Avoids re-processing files that are already efficiently encoded
* **Graceful shutdown**: Properly handles container stop signals and cleanup
* Monitor progress with `tail -f service/logs/current.log` and size savings in notifications
* For best results with SD content, enable `FORCE_ENCODE_SD=true` and consider `USE_CRF=true`

---

## � Troubleshooting

### Hardware Encoding Issues

If you see errors like:
```
[hevc_qsv @ 0x...] Low power mode is unsupported
[hevc_qsv @ 0x...] Current frame rate is unsupported
[hevc_qsv @ 0x...] some encoding parameters are not supported by the QSV runtime
```

**Solutions:**
1. **Automatic Fallback**: The script will automatically retry with software encoding (`libx265`)
2. **Manual Override**: Set `VIDEO_CODEC=libx265` to use software encoding exclusively
3. **Alternative Codecs**: Try `VIDEO_CODEC=libx264` for broader compatibility

### Common Hardware Encoding Problems:
- **Unsupported frame rates**: Some unusual frame rates aren't supported by QSV
- **Resolution limitations**: Very high or unusual resolutions may fail
- **Driver issues**: Outdated Intel graphics drivers
- **Container limitations**: `/dev/dri` device not properly mapped

### Performance Tuning:
```bash
# For systems without hardware acceleration:
VIDEO_CODEC=libx265
FALLBACK_CODEC=libx264

# For better compatibility with older hardware:
VIDEO_CODEC=libx264
FALLBACK_CODEC=libx264

# For maximum quality (slower):
USE_CRF=true
PRESET_HD=slow
PRESET_SD=slow
```

---

## �👋 Credits

Built with ❤️ by automation nerds and optimized for Plex DVR cleanup.

Heavily optimized for superior SD content compression while maintaining HD quality standards.