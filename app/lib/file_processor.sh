#!/bin/bash
# File processing workflow

create_temp_job_dir() {
    local base_path="$1"
    local safe_base="${base_path//\//_}"

    if [[ -z "$safe_base" ]]; then
        safe_base="job"
    fi

    mkdir -p "$TEMP_DIR" || return 1
    mktemp -d -- "${TEMP_DIR%/}/${safe_base}.XXXXXX"
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

    if [[ -f "$output_path" ]]; then
        log_info "Skipping, final file already exists: $file"
        return
    fi

    # Use a unique temporary directory for each job to avoid collisions.
    local temp_job_dir
    if ! temp_job_dir="$(create_temp_job_dir "$base_path")"; then
        log_error "Unable to create temporary job directory for $file"
        echo "$file" >> "$LOG_DIR/error.log"
        return 1
    fi
    local temp_output_path="${temp_job_dir}/$(basename "$output_path")"

    # Cleanup function for the temporary directory
    cleanup() {
        if [[ "$CLEANUP_TEMP_ON_FAILURE" != "true" ]] && [[ "${1:-}" == "failure" ]]; then
            log_warn "Temporary files for failed job kept at $temp_job_dir"
        else
            rm -rf "$temp_job_dir"
        fi
    }

    # Ensure temp and output directories exist
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
        return 0
    else
        log_error "Failed to process $file"
        echo "$file" >> "$LOG_DIR/error.log"
        cleanup "failure"
        return 1
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
                    job_count=$((job_count - 1))
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
        job_count=$((job_count + 1))
        
    done
    
    # Wait for remaining jobs to complete
    log_info "Waiting for remaining $job_count jobs to complete..."
    for pid in "${pids[@]}"; do
        wait "$pid" || true
    done
}
