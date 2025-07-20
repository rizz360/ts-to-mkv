# ts-cleanup 🧼📺

A smart, automated `.ts` cleaner and shrinker for Plex DVR recordings.

This Docker-based tool converts `.ts` files to smaller `.mkv` containers, keeping **all audio/subtitle streams**, adding a `.TV.{resolution}.mkv` suffix, and optionally deleting the originals. Ideal for archival and cleanup tasks after long-term DVR usage.

---

## ✅ Features

- 🔁 **Recursively processes** all `.ts` files in `/input`
- 🗂 **Preserves subfolder structure** in `/output`
- 🧠 Adds `.TV.720p.mkv`, `.TV.480i.mkv`, etc. suffixes based on resolution and scan type
- ⚡ **Uses Intel QSV (Quick Sync Video)** hardware acceleration if available
- 📼 Automatically chooses between **remux** (lossless container change) or **H.265 re-encode**
- 🎚 Configurable via `.env` file
- 🧹 Optionally deletes `.ts` files after successful processing
- 📋 Minimal log files: queue, current, done, failed

---

## 🧾 File Structure

```

ts-cleanup/
├── docker-compose.yml
├── config/
│   └── cleanup.env
├── service/
│   ├── cleanup.sh
│   └── logs/

```

---

## 🚀 Setup

### 1. Mount your input/output folders

Edit `docker-compose.yml`:

```yaml
volumes:
  - /mnt/hjem_nas_media/Movies:/input
  - /mnt/hjem_nas_media/Movies-clean:/output
```

### 2. Configure behavior

Edit `config/cleanup.env`:

```bash
DELETE_TS=true           # Delete .ts files after success
REMUX_SIZE_GB=5          # Files larger than this will be re-encoded
VIDEO_CODEC=hevc_qsv     # Use Intel QSV hardware encoder
VIDEO_CRF=23             # (Used only if fallback to libx265 is added)
AUDIO_CODEC=copy         # Copy all audio streams
```

### 3. Launch the container

```bash
docker compose up --build
```

---

## 🔎 Logs and Monitoring

You can inspect logs inside `service/logs/`:

| File          | Purpose                        |
| ------------- | ------------------------------ |
| `queue.log`   | List of `.ts` files to process |
| `current.log` | Currently processed file       |
| `done.log`    | Successfully converted files   |
| `error.log`   | Failed files                   |

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

* Uses `ffprobe` to determine resolution and scan type
* Leaves all non-`.ts` files untouched
* Use a host `cron` to run this periodically, or wrap it in a `while true` loop with `sleep`

---

## 👋 Credits

Built with ❤️ by automation nerds and optimized for Plex DVR cleanup.
