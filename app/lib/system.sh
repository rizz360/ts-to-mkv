#!/bin/bash
# System utilities and dependency checks

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
    ntfy_send "ts-to-mkv processor stopped"
    exit 0
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

setup_signal_handlers() {
    # Set up signal handlers for graceful shutdown
    trap shutdown_handler SIGTERM SIGINT SIGQUIT
}

init_directories() {
    mkdir -p "$TEMP_DIR" # Ensure base temp directory exists
    init_logging
}
