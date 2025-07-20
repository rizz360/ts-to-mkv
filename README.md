# ts-to-mkv 🧼📺

A smart, automated `.ts` cleaner and shrinker for Plex DVR recordings.

This Docker-based tool converts `.ts` files to smaller `.mkv` containers, keeping **all audio/subtitle streams**, adding a `.TV.{resolution}.mkv` suffix, and optionally deleting the originals. Ideal for archival and cleanup tasks after long-term DVR usage.

---

## ✅ Features

- 🔁 **Recursively processes** all `.ts` files in `/input`
- 🗂 **Preserves subfolder structure** in `/output`
- 🧠 Adds `.TV.720p.mkv`, `.TV.480i.mkv`, etc. suffixes based on resolution and scan type
- ⚡ **Uses Intel QSV (Quick Sync Video)** hardware acceleration if available
- 📼 Automatically chooses between **remux** (lossless container change) or **H.265 re-encode**
- 🔄 **Smart remux fallback** - retries without subtitles if initial remux fails
- 🎚 Configurable via `.env` file
- 🧹 Optionally deletes `.ts` files after successful processing
- 📋 Comprehensive logging: queue, current, done, failed
- 📱 **Push notifications** via Ntfy (optional)
- 📊 **File size reduction tracking** with percentage savings
- ✅ **Duration validation** ensures encoded files match original length

---

## 🧾 File Structure

```
ts-to-mkv/
├── docker-compose.yml
├── Dockerfile
├── service/
│   ├── cleanup.env
│   ├── cleanup.sh
│   └── logs/          # Created automatically at runtime
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
REMUX_SIZE_GB=3                     # Files larger than this will be re-encoded
REMUX_FALLBACK_NO_SUBTITLES=true    # Retry remux without subtitles if failed

# --- Encoding Settings ---
VIDEO_CODEC=hevc_qsv                # Use Intel QSV hardware encoder
VIDEO_BITRATE=2500k                 # Bitrate for encoding (e.g. 2000k, 2500k, 4M)
VIDEO_PRESET=fast                   # QSV preset: veryfast, fast, medium, slow, etc.
AUDIO_CODEC=copy                    # Copy all audio streams

# --- Notifications ---
NTFY_URL=http://192.168.1.119:1888/ts-to-mkv  # Optional: ntfy endpoint for notifications
```

### 3. Launch the container

```bash
docker compose up --build
```

---

## 📱 Notifications (Optional)

The tool can send push notifications via Ntfy when processing completes:

1. Set up an Ntfy server or use a public instance
2. Configure `NTFY_URL` in `service/cleanup.env`
3. Notifications include:
   - Processing start/completion
   - File size reduction statistics
   - Individual file completion status

Example notification: `"movie.TV.1080i.mkv - Size reduced from 2500MB to 800MB (68% reduction)"`

---

## 🔎 Logs and Monitoring

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

| Input File           | Resolution | Output File                   |
| -------------------- | ---------- | ----------------------------- |
| `Show1/ep1.ts`       | 720p       | `Show1/ep1.TV.720p.mkv`       |
| `Movie/recording.ts` | 480i       | `Movie/recording.TV.480i.mkv` |
| `Event/2024.ts`      | 1080i      | `Event/2024.TV.1080i.mkv`     |

---

## 💡 Tips

* Uses `ffprobe` to determine resolution and scan type automatically
* Leaves all non-`.ts` files untouched
* **Smart processing**: Files ≤ `REMUX_SIZE_GB` are remuxed (fast), larger files are re-encoded
* **Fallback handling**: If remux fails due to subtitle compatibility, automatically retries without subtitles
* **Quality assurance**: Validates encoded file duration against original (±20% tolerance)
* **Hardware optimization**: Leverages Intel QSV for efficient H.265 encoding
* Use a host `cron` to run this periodically, or wrap it in a `while true` loop with `sleep`
* Monitor progress with `tail -f service/logs/current.log` and size savings in notifications

---

## 👋 Credits

Built with ❤️ by automation nerds and optimized for Plex DVR cleanup.
