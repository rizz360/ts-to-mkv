#!/bin/bash
# Logging and notification utilities

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
        curl -s -X POST -H "Title: ts-to-mkv" -H "Priority: default" \
            -d "$message" \
            "$NTFY_URL" > /dev/null || true
    fi
}

# Initialize logging directories
init_logging() {
    mkdir -p "$LOG_DIR"
    >"$LOG_DIR/current.log"
}

# Log processing statistics
log_stats() {
    local done_count error_count
    done_count=$(wc -l < "$LOG_DIR/done.log" 2>/dev/null || echo 0)
    error_count=$(wc -l < "$LOG_DIR/error.log" 2>/dev/null || echo 0)
    
    log_info "Processing stats: $done_count successful, $error_count failed"
    echo "$done_count:$error_count"
}
