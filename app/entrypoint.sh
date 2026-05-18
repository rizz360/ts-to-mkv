#!/bin/bash
# Main script - ts2mkv processor
# Modular refactored version

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Source all library modules
source "$LIB_DIR/system.sh"      # Must be first (sets error handling and logging functions)
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/video_analysis.sh"
source "$LIB_DIR/encoding.sh"
source "$LIB_DIR/file_processor.sh"
source "$LIB_DIR/file_monitor.sh"

main() {
    # Initialize system
    setup_signal_handlers
    
    # Load and validate configuration
    load_config
    validate_config

    # Start web dashboard after config is loaded so LOG_DIR and WEB_PORT are resolved.
    export LOG_DIR WEB_PORT
    python3 /app/web/server.py &
    
    # Check dependencies
    check_dependencies
    
    # Initialize directories and logging
    init_directories
    
    # Send startup notification
    ntfy_send "ts2mkv processor starting in $MONITOR_MODE mode..."

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

# Run main function
main "$@"
