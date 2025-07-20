#!/bin/bash
# Stricter error handling
set -euo pipefail

# --- Configuration & Setup ---
if [ -f "/service/cleanup.env" ]; then
    source /service/cleanup.env
else
    printf "[%s] [ERROR] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "Configuration file /service/cleanup.env not found. Exiting."
    exit 1
fi

LOG_DIR="/service/logs"
INPUT_DIR="/input"
OUTPUT_DIR="/output"

DELETE_TS="${DELETE_TS:-false}"
REMUX_SIZE_GB="${REMUX_SIZE_GB:-2}"
VIDEO_CODEC="${VIDEO_CODEC:-hevc_qsv}"
VIDEO_BITRATE="${VIDEO_BITRATE:-2500k}"
VIDEO_PRESET="${VIDEO_PRESET:-fast}"
AUDIO_CODEC="${AUDIO_CODEC:-copy}"
REMUX_FALLBACK_NO_SUBTITLES="${REMUX_FALLBACK_NO_SUBTITLES:-true}"

# --- Logging Functions ---
log_info() {
    printf "[%s] [INFO] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$1"
}

log_warn() {
    printf "[%s] [WARN] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$1"
}

log_error() {
    printf "[%s] [ERROR] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$1"
}

ntfy_send() {
    local message="$1"
    curl -s -X POST -H "Title: TS-to-MKV" -H "Priority: default" \
        -d "$message" \
        "$NTFY_URL" > /dev/null
}

check_dependencies() {
    log_info "Checking for dependencies..."
    for cmd in ffmpeg ffprobe jq; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Command not found: $cmd. Please install it. Exiting."
            exit 1
        fi
    done
    log_info "All dependencies found."
}

get_video_info() {
    local file_path="$1"
    local -n info_ref="$2"

    local json_data
    json_data=$(ffprobe -v quiet -print_format json -show_format -show_streams "$file_path")

    info_ref[height]=$(echo "$json_data" | jq -r '.streams[] | select(.codec_type=="video") | .height' | head -n1)
    info_ref[scan_type]=$(echo "$json_data" | jq -r '.streams[] | select(.codec_type=="video") | .field_order // "progressive"' | head -n1)
    info_ref[duration]=$(echo "$json_data" | jq -r '.format.duration | tonumber | floor')
    info_ref[size_gb]=$(du -BG "$file_path" | cut -f1 | sed 's/G//')

    if [[ "${info_ref[scan_type]}" =~ (tt|bb|tb|bt) ]]; then
        info_ref[res_label]="${info_ref[height]}i"
    else
        info_ref[res_label]="${info_ref[height]}p"
    fi
}

remux_file() {
    local input_file="$1"
    local output_path="$2"

    log_info "Attempting to remux $input_file"
    if ffmpeg -hide_banner -loglevel error -i "$input_file" -map 0 -c copy "$output_path"; then
        return 0
    elif [[ "$REMUX_FALLBACK_NO_SUBTITLES" == "true" ]]; then
        log_warn "Remux failed. Retrying without subtitles..."
        rm -f "$output_path"
        if ffmpeg -y -hide_banner -loglevel error -i "$input_file" -map 0 -sn -c copy "$output_path"; then
            return 0
        fi
    fi
    return 1
}

encode_file() {
    local input_file="$1"
    local output_path="$2"
    local duration_sec="$3"

    log_info "Encoding $input_file"
    local encode_log="$LOG_DIR/ffmpeg_encode_$(basename "$input_file").log"

    if ! ffmpeg -hide_banner -loglevel error \
        -hwaccel qsv -init_hw_device qsv=hw:/dev/dri/renderD128 -filter_hw_device hw \
        -i "$input_file" -map 0 -sn \
        -c:v "$VIDEO_CODEC" -preset "$VIDEO_PRESET" -b:v "$VIDEO_BITRATE" \
        -c:a "$AUDIO_CODEC" \
        -y "$output_path" > "$encode_log" 2>&1; then
        log_error "Encoding failed for $input_file. Check logs at $encode_log"
        return 1
    fi

    local actual_duration
    actual_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$output_path" | awk '{printf "%.0f\n", $1}')
    if (( actual_duration < duration_sec * 80 / 100 )); then
        log_warn "Encoded duration ($actual_duration) is much shorter than original ($duration_sec)!"
        return 1
    fi
    return 0
}

process_file() {
    local file="$1"

    if [ ! -e "$file" ]; then
        log_warn "File no longer exists, skipping: $file"
        return
    fi

    echo "===================="
    echo "$file" > "$LOG_DIR/current.log"

    local relative_path="${file#${INPUT_DIR}/}"
    local base_path="${relative_path%.ts}"

    declare -A video_info
    get_video_info "$file" video_info

    local suffix="TV.${video_info[res_label]}"
    local output_rel="${base_path}.${suffix}.mkv"
    local output_path="${OUTPUT_DIR}/${output_rel}"

    local output_dir
    output_dir=$(dirname "$output_path")
    local temp_output_path="${output_dir}/.temp_$(basename "$output_path")"

    if [[ -f "$output_path" ]]; then
        log_info "Skipping, final file already exists: $file"
        return
    fi

    rm -f "$temp_output_path"
    mkdir -p "$output_dir"

    log_info "Processing ${file} (${video_info[size_gb]}GB, ${video_info[res_label]})"

    local success=false
    if (( video_info[size_gb] <= REMUX_SIZE_GB )); then
        if remux_file "$file" "$temp_output_path"; then
            success=true
        fi
    else
        if encode_file "$file" "$temp_output_path" "${video_info[duration]}"; then
            success=true
        fi
    fi

    if [[ "$success" == "true" ]]; then
        log_info "Processing successful, renaming to final destination."
        mv "$temp_output_path" "$output_path"

        log_info "Successfully created $output_path"
        echo "$file" >> "$LOG_DIR/done.log"

        local in_size_mb out_size_mb
        in_size_mb=$(du -m "$file" | cut -f1)
        out_size_mb=$(du -m "$output_path" | cut -f1)

        local ntfy_message
        if (( in_size_mb > 0 )); then
            local percent_saved=$(( 100 - (out_size_mb * 100 / in_size_mb) ))
            log_info "Size reduced from ${in_size_mb}MB to ${out_size_mb}MB (${percent_saved}% reduction)."
            ntfy_message="$(basename "$output_path") - Size reduced from ${in_size_mb}MB to ${out_size_mb}MB (${percent_saved}% reduction)"
        else
            ntfy_message="$(basename "$output_path") - Finished processing"
        fi

        ntfy_send "$ntfy_message"

        if [[ "$DELETE_TS" == "true" ]]; then
            rm "$file"
            log_info "Deleted source file: $file"
        fi
    else
        log_error "Failed to process $file"
        echo "$file" >> "$LOG_DIR/error.log"
        rm -f "$temp_output_path"
    fi
}

main() {
    check_dependencies

    ntfy_send "Getting started..."

    mkdir -p "$LOG_DIR"
    local queue_file="$LOG_DIR/queue.log"
    >"$queue_file"
    >"$LOG_DIR/current.log"

    log_info "Recursively scanning $INPUT_DIR for .ts files..."
    find "$INPUT_DIR" -type f -name '*.ts' > "$queue_file"
    log_info "Found $(wc -l < "$queue_file") files to process."

    mapfile -t file_list < "$queue_file"

    for file in "${file_list[@]}"; do
        if [ -z "$file" ]; then
            continue
        fi
        process_file "$file"
    done

    > "$LOG_DIR/current.log"
    log_info "All conversions complete."
}

main
