#!/bin/bash
# Stricter error handling
set -euo pipefail

# Graceful shutdown handler
shutdown_handler() {
    log_info "Received shutdown signal. Cleaning up..."
    
    # Kill any background jobs
    local jobs
    jobs=$(jobs -p)
    if [[ -n "$jobs" ]]; then
        log_info "Terminating background jobs..."
        kill $jobs 2>/dev/null || true
        wait 2>/dev/null || true
    fi
    
    # Clean up current processing indicator
    > "$LOG_DIR/current.log" 2>/dev/null || true
    
    log_info "Shutdown complete."
    ntfy_send "TS-to-MKV processor stopped"
    exit 0
}

# Set up signal handlers for graceful shutdown
trap shutdown_handler SIGTERM SIGINT SIGQUIT

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

# Set defaults for all configuration variables
DELETE_TS="${DELETE_TS:-false}"
REMUX_SIZE_GB="${REMUX_SIZE_GB:-3}"
VIDEO_CODEC="${VIDEO_CODEC:-hevc_qsv}"
FALLBACK_CODEC="${FALLBACK_CODEC:-libx265}"
AUDIO_CODEC="${AUDIO_CODEC:-copy}"
REMUX_FALLBACK_NO_SUBTITLES="${REMUX_FALLBACK_NO_SUBTITLES:-true}"

# Processing mode settings
MONITOR_MODE="${MONITOR_MODE:-watch}"
POLL_INTERVAL="${POLL_INTERVAL:-300}"

# Parallel processing settings
ENABLE_PARALLEL_PROCESSING="${ENABLE_PARALLEL_PROCESSING:-false}"
MAX_CONCURRENT_JOBS="${MAX_CONCURRENT_JOBS:-2}"

# Processing logic settings
FORCE_ENCODE_SD="${FORCE_ENCODE_SD:-true}"

# Resolution-specific bitrates
BITRATE_1080="${BITRATE_1080:-4000k}"
BITRATE_720="${BITRATE_720:-2500k}"
BITRATE_576="${BITRATE_576:-1500k}"
BITRATE_480="${BITRATE_480:-1200k}"
BITRATE_DEFAULT="${BITRATE_DEFAULT:-2000k}"

# CRF settings
USE_CRF="${USE_CRF:-false}"
CRF_1080="${CRF_1080:-23}"
CRF_720="${CRF_720:-24}"
CRF_576="${CRF_576:-26}"
CRF_480="${CRF_480:-28}"
CRF_DEFAULT="${CRF_DEFAULT:-24}"

# Preset settings
PRESET_HD="${PRESET_HD:-fast}"
PRESET_SD="${PRESET_SD:-medium}"

# Advanced settings
SKIP_ALREADY_HEVC="${SKIP_ALREADY_HEVC:-true}"
HEVC_BITRATE_THRESHOLD="${HEVC_BITRATE_THRESHOLD:-3000000}"

# Temporary file management
TEMP_DIR="${TEMP_DIR:-/tmp/ts-processing}"
CLEANUP_TEMP_ON_FAILURE="${CLEANUP_TEMP_ON_FAILURE:-true}"

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
    if [[ -n "${NTFY_URL:-}" ]]; then
        curl -s -X POST -H "Title: TS-to-MKV" -H "Priority: default" \
            -d "$message" \
            "$NTFY_URL" > /dev/null || true
    fi
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

    # Get additional stream info for optimization decisions
    info_ref[video_bitrate]=$(echo "$json_data" | jq -r '.streams[] | select(.codec_type=="video") | .bit_rate // "0"')
    info_ref[video_codec]=$(echo "$json_data" | jq -r '.streams[] | select(.codec_type=="video") | .codec_name // "unknown"')
}

get_encoding_params() {
    local resolution="$1"
    local -n params_ref="$2"

    # Determine bitrate/CRF based on resolution (handles both p and i variants)
    local res_num="${resolution%[pi]}"
    
    if [[ "$USE_CRF" == "true" ]]; then
        case "$res_num" in
            1080) params_ref[quality]="-crf $CRF_1080" ;;
            720) params_ref[quality]="-crf $CRF_720" ;;
            576) params_ref[quality]="-crf $CRF_576" ;;
            480) params_ref[quality]="-crf $CRF_480" ;;
            *) params_ref[quality]="-crf $CRF_DEFAULT" ;;
        esac
        
        # Set maxrate as well for CRF
        case "$res_num" in
            1080) params_ref[quality]+=" -maxrate $BITRATE_1080 -bufsize $((${BITRATE_1080%k} * 2))k" ;;
            720) params_ref[quality]+=" -maxrate $BITRATE_720 -bufsize $((${BITRATE_720%k} * 2))k" ;;
            576) params_ref[quality]+=" -maxrate $BITRATE_576 -bufsize $((${BITRATE_576%k} * 2))k" ;;
            480) params_ref[quality]+=" -maxrate $BITRATE_480 -bufsize $((${BITRATE_480%k} * 2))k" ;;
            *) params_ref[quality]+=" -maxrate $BITRATE_DEFAULT -bufsize $((${BITRATE_DEFAULT%k} * 2))k" ;;
        esac
    else
        case "$res_num" in
            1080) params_ref[quality]="-b:v $BITRATE_1080" ;;
            720) params_ref[quality]="-b:v $BITRATE_720" ;;
            576) params_ref[quality]="-b:v $BITRATE_576" ;;
            480) params_ref[quality]="-b:v $BITRATE_480" ;;
            *) params_ref[quality]="-b:v $BITRATE_DEFAULT" ;;
        esac
    fi

    # Determine preset based on resolution
    if [[ "$res_num" -le 576 ]]; then
        params_ref[preset]="$PRESET_SD"
    else
        params_ref[preset]="$PRESET_HD"
    fi
}

should_encode() {
    local file="$1"
    local size_gb="$2"
    local resolution="$3"
    local video_codec="$4"
    local video_bitrate="$5"

    local res_num="${resolution%[pi]}"

    # Skip if already efficiently encoded with HEVC
    if [[ "$SKIP_ALREADY_HEVC" == "true" ]] && [[ "$video_codec" == "hevc" ]] && [[ "$video_bitrate" != "0" ]] && (( video_bitrate < HEVC_BITRATE_THRESHOLD )); then
        log_info "Skipping $file - already efficiently encoded with HEVC (${video_bitrate} bps)"
        return 1
    fi

    # Always encode SD content for better compression if enabled
    if [[ "$FORCE_ENCODE_SD" == "true" ]] && (( res_num <= 576 )); then
        log_info "Will encode SD content ($resolution) for better compression"
        return 0
    fi
    
    # For HD content, use size threshold
    if (( size_gb > REMUX_SIZE_GB )); then
        log_info "Will encode large file (${size_gb}GB > ${REMUX_SIZE_GB}GB threshold)"
        return 0
    fi
    
    log_info "Will remux (${size_gb}GB <= ${REMUX_SIZE_GB}GB threshold)"
    return 1
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
    local resolution="$4"

    declare -A encoding_params
    get_encoding_params "$resolution" encoding_params

    log_info "Encoding $input_file (${resolution}) with preset ${encoding_params[preset]}"
    local encode_log="$LOG_DIR/ffmpeg_encode_$(basename "$input_file").log"

    # Try primary codec first
    if try_encode_with_codec "$input_file" "$output_path" "$duration_sec" "$resolution" "$VIDEO_CODEC" "$encode_log"; then
        return 0
    fi

    # If primary codec failed and it's a hardware codec, try fallback
    if [[ "$VIDEO_CODEC" =~ qsv|nvenc|vaapi ]] && [[ "$FALLBACK_CODEC" != "$VIDEO_CODEC" ]]; then
        log_warn "Hardware encoding failed for $input_file, trying fallback codec: $FALLBACK_CODEC"
        rm -f "$output_path" # Clean up failed attempt
        
        if try_encode_with_codec "$input_file" "$output_path" "$duration_sec" "$resolution" "$FALLBACK_CODEC" "$encode_log"; then
            return 0
        fi
    fi

    log_error "All encoding attempts failed for $input_file. Check logs at $encode_log"
    return 1
}

try_encode_with_codec() {
    local input_file="$1"
    local output_path="$2"
    local duration_sec="$3"
    local resolution="$4"
    local codec="$5"
    local encode_log="$6"

    declare -A encoding_params
    get_encoding_params "$resolution" encoding_params

    # Build ffmpeg command based on codec type
    local ffmpeg_cmd=(ffmpeg -hide_banner -loglevel error)
    
    # Add hardware acceleration for QSV
    if [[ "$codec" == "hevc_qsv" ]]; then
        ffmpeg_cmd+=(-hwaccel qsv -init_hw_device qsv=hw:/dev/dri/renderD128 -filter_hw_device hw)
    fi
    
    ffmpeg_cmd+=(-i "$input_file" -map 0 -sn -c:v "$codec" -preset "${encoding_params[preset]}")

    # Add quality parameters (either CRF or bitrate)
    read -ra quality_params <<< "${encoding_params[quality]}"
    ffmpeg_cmd+=("${quality_params[@]}")

    # Add audio codec and output
    ffmpeg_cmd+=(-c:a "$AUDIO_CODEC" -y "$output_path")

    log_info "Attempting encoding with $codec: ${ffmpeg_cmd[*]}"
    
    if ! "${ffmpeg_cmd[@]}" > "$encode_log" 2>&1; then
        log_warn "Encoding with $codec failed for $input_file"
        return 1
    fi

    # Validate output duration
    if ! validate_output "$input_file" "$output_path" "$duration_sec" "$resolution"; then
        log_error "Output validation failed for $input_file with $codec"
        return 1
    fi

    log_info "Successfully encoded $input_file with $codec"
    return 0
}

validate_output() {
    local original="$1"
    local encoded="$2"
    local original_duration="$3"
    local resolution="$4"

    local encoded_duration
    encoded_duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$encoded" | awk '{printf "%.0f\n", $1}')
    
    # More lenient duration check for SD content (often has timing irregularities)
    local tolerance=80
    local res_num="${resolution%[pi]}"
    if (( res_num <= 576 )); then
        tolerance=70
    fi
    
    if (( encoded_duration < original_duration * tolerance / 100 )); then
        log_warn "Encoded duration ($encoded_duration) is much shorter than original ($original_duration)!"
        return 1
    fi
    
    # Ensure some compression occurred (but allow for edge cases)
    local encoded_size original_size
    encoded_size=$(stat -f%z "$encoded" 2>/dev/null || stat -c%s "$encoded")
    original_size=$(stat -f%z "$original" 2>/dev/null || stat -c%s "$original")
    
    if (( encoded_size >= original_size )); then
        log_warn "Encoded file is not smaller than original - this may be expected for some content"
    fi
    
    return 0
}

process_file() {
    local file="$1"

    if [ ! -e "$file" ]; then
        log_warn "File no longer exists, skipping: $file"
        return
    fi

    log_info "===================="
    echo "$file" > "$LOG_DIR/current.log"

    local relative_path="${file#${INPUT_DIR}/}"
    local base_path="${relative_path%.ts}"

    declare -A video_info
    get_video_info "$file" video_info

    local suffix="TV.${video_info[res_label]}"
    local output_rel="${base_path}.${suffix}.mkv"
    local output_path="${OUTPUT_DIR}/${output_rel}"

    # Use a dedicated temporary directory for processing
    local temp_job_dir="${TEMP_DIR}/$(basename "${base_path}").$$"
    local temp_output_path="${temp_job_dir}/$(basename "$output_path")"

    # Cleanup function for the temporary directory
    cleanup() {
        if [[ "$CLEANUP_TEMP_ON_FAILURE" != "true" ]] && [[ "${1:-}" == "failure" ]]; then
            log_warn "Temporary files for failed job kept at $temp_job_dir"
        else
            rm -rf "$temp_job_dir"
        fi
    }

    if [[ -f "$output_path" ]]; then
        log_info "Skipping, final file already exists: $file"
        return
    fi

    # Ensure temp and output directories exist
    mkdir -p "$temp_job_dir"
    mkdir -p "$(dirname "$output_path")"

    log_info "Processing ${file} (${video_info[size_gb]}GB, ${video_info[res_label]}, ${video_info[video_codec]}, ${video_info[video_bitrate]} bps)"
    log_info "Using temporary directory: $temp_job_dir"

    local success=false
    
    if should_encode "$file" "${video_info[size_gb]}" "${video_info[res_label]}" "${video_info[video_codec]}" "${video_info[video_bitrate]}"; then
        if encode_file "$file" "$temp_output_path" "${video_info[duration]}" "${video_info[res_label]}"; then
            success=true
        fi
    else
        if remux_file "$file" "$temp_output_path"; then
            success=true
        fi
    fi

    if [[ "$success" == "true" ]]; then
        log_info "Processing successful, moving to final destination."
        mv "$temp_output_path" "$output_path"
        cleanup "success"

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
        cleanup "failure"
    fi
}

process_files_sequential() {
    local -a file_list
    
    # Use mapfile to properly handle filenames with special characters
    mapfile -t file_list < "$1"
    
    for file in "${file_list[@]}"; do
        if [ -z "$file" ]; then
            continue
        fi
        process_file "$file"
    done
}

process_files_parallel() {
    local -a file_list
    local -a pids=()
    local job_count=0
    
    # Use mapfile to properly handle filenames with special characters
    mapfile -t file_list < "$1"
    
    log_info "Processing files with up to $MAX_CONCURRENT_JOBS concurrent jobs"
    
    for file in "${file_list[@]}"; do
        if [ -z "$file" ]; then continue; fi
        
        # Wait for a slot if we're at max capacity
        while (( job_count >= MAX_CONCURRENT_JOBS )); do
            # Check if any jobs have completed
            local new_pids=()
            for pid in "${pids[@]}"; do
                if kill -0 "$pid" 2>/dev/null; then
                    new_pids+=("$pid")
                else
                    ((job_count--))
                fi
            done
            pids=("${new_pids[@]}")
            
            # Brief sleep to avoid busy waiting
            if (( job_count >= MAX_CONCURRENT_JOBS )); then
                sleep 1
            fi
        done
        
        # Start new job
        process_file "$file" &
        local new_pid=$!
        pids+=("$new_pid")
        ((job_count++))
        
    done
    
    # Wait for remaining jobs to complete
    log_info "Waiting for remaining $job_count jobs to complete..."
    for pid in "${pids[@]}"; do
        wait "$pid" || true
    done
}

process_existing_files() {
    local queue_file="$LOG_DIR/queue.log"
    >"$queue_file"

    log_info "Scanning $INPUT_DIR for existing .ts files..."
    find "$INPUT_DIR" -type f -name '*.ts' > "$queue_file"
    local total_files
    total_files=$(wc -l < "$queue_file")
    log_info "Found $total_files existing files to process."

    if (( total_files == 0 )); then
        log_info "No existing .ts files found to process."
        return 0
    fi

    log_info "Configuration summary:"
    log_info "- Primary video codec: $VIDEO_CODEC"
    log_info "- Fallback video codec: $FALLBACK_CODEC"
    log_info "- Parallel processing: $ENABLE_PARALLEL_PROCESSING"
    if [[ "$ENABLE_PARALLEL_PROCESSING" == "true" ]]; then
        log_info "- Max concurrent jobs: $MAX_CONCURRENT_JOBS"
    fi
    log_info "- Force encode SD content: $FORCE_ENCODE_SD"
    log_info "- Use CRF mode: $USE_CRF"
    log_info "- Skip already HEVC: $SKIP_ALREADY_HEVC"

    # Process files based on parallel processing setting
    if [[ "$ENABLE_PARALLEL_PROCESSING" == "true" ]] && (( MAX_CONCURRENT_JOBS > 1 )); then
        process_files_parallel "$queue_file"
    else
        log_info "Processing existing files sequentially..."
        process_files_sequential "$queue_file"
    fi

    > "$LOG_DIR/current.log"
    log_info "Existing file processing complete."
    
    local done_count error_count
    done_count=$(wc -l < "$LOG_DIR/done.log" 2>/dev/null || echo 0)
    error_count=$(wc -l < "$LOG_DIR/error.log" 2>/dev/null || echo 0)
    
    ntfy_send "Existing files processed: $done_count successful, $error_count failed out of $total_files total files"
}

wait_for_new_files() {
    log_info "Starting file system monitoring for new .ts files in $INPUT_DIR"
    log_info "Waiting for new files to be added..."
    
    while true; do
        # Use inotifywait to monitor for new files
        # Monitor for: moved_to (mv command), close_write (copy completion), create (new files)
        local new_file
        new_file=$(inotifywait -r -e moved_to,close_write,create --format '%w%f' "$INPUT_DIR" 2>/dev/null | grep '\.ts$' | head -n1)
        
        if [[ -n "$new_file" && -f "$new_file" ]]; then
            log_info "Detected new file: $new_file"
            
            # Wait a moment to ensure file is completely written
            sleep 5
            
            # Verify file still exists and process it
            if [[ -f "$new_file" ]]; then
                log_info "Processing newly detected file: $new_file"
                process_file "$new_file"
                
                local done_count error_count
                done_count=$(wc -l < "$LOG_DIR/done.log" 2>/dev/null || echo 0)
                error_count=$(wc -l < "$LOG_DIR/error.log" 2>/dev/null || echo 0)
                
                log_info "File processing complete. Total processed: $done_count successful, $error_count failed"
            else
                log_warn "File disappeared before processing: $new_file"
            fi
        fi
        
        # Brief sleep to prevent excessive CPU usage in case inotifywait exits unexpectedly
        sleep 1
    done
}

poll_for_new_files() {
    log_info "Starting periodic polling for new .ts files in $INPUT_DIR (every ${POLL_INTERVAL} seconds)"
    
    # Keep track of previously processed files
    local processed_files_cache="$LOG_DIR/processed_cache.log"
    touch "$processed_files_cache"
    
    while true; do
        local queue_file="$LOG_DIR/poll_queue.log"
        >"$queue_file"
        
        # Find all .ts files
        find "$INPUT_DIR" -type f -name '*.ts' > "$queue_file"
        
        # Process only new files (not in our cache)
        local new_files=0
        while IFS= read -r file; do
            if [[ -n "$file" ]] && ! grep -Fxq "$file" "$processed_files_cache"; then
                log_info "Found new file to process: $file"
                process_file "$file"
                echo "$file" >> "$processed_files_cache"
                ((new_files++))
            fi
        done < "$queue_file"
        
        if (( new_files > 0 )); then
            local done_count error_count
            done_count=$(wc -l < "$LOG_DIR/done.log" 2>/dev/null || echo 0)
            error_count=$(wc -l < "$LOG_DIR/error.log" 2>/dev/null || echo 0)
            
            log_info "Processed $new_files new files. Total processed: $done_count successful, $error_count failed"
        else
            log_info "No new files found during this scan"
        fi
        
        log_info "Waiting ${POLL_INTERVAL} seconds before next scan..."
        sleep "$POLL_INTERVAL"
    done
}

main() {
    check_dependencies

    # Validate monitor mode
    case "$MONITOR_MODE" in
        watch|poll|once)
            log_info "Running in $MONITOR_MODE mode"
            ;;
        *)
            log_error "Invalid MONITOR_MODE: $MONITOR_MODE. Must be 'watch', 'poll', or 'once'"
            exit 1
            ;;
    esac

    # Check dependencies based on monitor mode
    if [[ "$MONITOR_MODE" == "watch" ]] && ! command -v inotifywait &> /dev/null; then
        log_error "inotifywait not found. Please install inotify-tools package or use MONITOR_MODE=poll"
        exit 1
    fi

    ntfy_send "TS-to-MKV processor starting in $MONITOR_MODE mode..."

    mkdir -p "$LOG_DIR"
    mkdir -p "$TEMP_DIR" # Ensure base temp directory exists
    >"$LOG_DIR/current.log"

    # Process any existing files first
    process_existing_files
    
    # Handle different monitoring modes
    case "$MONITOR_MODE" in
        once)
            log_info "Single run mode complete. Exiting."
            ntfy_send "Single run processing complete."
            ;;
        watch)
            ntfy_send "Now monitoring for new .ts files using file system events..."
            wait_for_new_files
            ;;
        poll)
            ntfy_send "Now monitoring for new .ts files using periodic polling (${POLL_INTERVAL}s intervals)..."
            poll_for_new_files
            ;;
    esac
}

main