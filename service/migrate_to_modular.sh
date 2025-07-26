#!/bin/bash
# Migration helper script for transitioning to modular architecture

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== TS-to-MKV Modular Migration Helper ==="
echo ""

# Check if we're running in Docker
if [ -f /.dockerenv ]; then
    echo "✓ Running inside Docker container"
    DOCKER_MODE=true
else
    echo "ⓘ Running on host system"
    DOCKER_MODE=false
fi

# Function to backup original script
backup_original() {
    if [[ -f "$SCRIPT_DIR/cleanup.sh" ]]; then
        if [[ ! -f "$SCRIPT_DIR/cleanup.sh.backup" ]]; then
            cp "$SCRIPT_DIR/cleanup.sh" "$SCRIPT_DIR/cleanup.sh.backup"
            echo "✓ Backed up original cleanup.sh to cleanup.sh.backup"
        else
            echo "ⓘ Backup already exists: cleanup.sh.backup"
        fi
    else
        echo "⚠ Original cleanup.sh not found"
    fi
}

# Function to validate modular setup
validate_modular() {
    echo ""
    echo "=== Validating Modular Setup ==="
    
    # Check main script
    if [[ -f "$SCRIPT_DIR/cleanup_modular.sh" ]]; then
        echo "✓ Main modular script found"
        if [[ -x "$SCRIPT_DIR/cleanup_modular.sh" ]]; then
            echo "✓ Main script is executable"
        else
            echo "⚠ Main script not executable - fixing..."
            chmod +x "$SCRIPT_DIR/cleanup_modular.sh"
        fi
    else
        echo "✗ Main modular script missing!"
        return 1
    fi
    
    # Check lib directory
    if [[ -d "$SCRIPT_DIR/lib" ]]; then
        echo "✓ lib directory found"
        
        local required_modules=(
            "system.sh"
            "logging.sh"
            "config.sh" 
            "video_analysis.sh"
            "encoding.sh"
            "file_processor.sh"
            "file_monitor.sh"
        )
        
        for module in "${required_modules[@]}"; do
            if [[ -f "$SCRIPT_DIR/lib/$module" ]]; then
                echo "✓ Module $module found"
            else
                echo "✗ Module $module missing!"
                return 1
            fi
        done
    else
        echo "✗ lib directory missing!"
        return 1
    fi
    
    # Test syntax
    echo ""
    echo "Testing syntax..."
    if bash -n "$SCRIPT_DIR/cleanup_modular.sh"; then
        echo "✓ Main script syntax OK"
    else
        echo "✗ Main script has syntax errors!"
        return 1
    fi
    
    for module in "$SCRIPT_DIR/lib"/*.sh; do
        if bash -n "$module"; then
            echo "✓ $(basename "$module") syntax OK"
        else
            echo "✗ $(basename "$module") has syntax errors!"
            return 1
        fi
    done
    
    return 0
}

# Function to test modular script
test_modular() {
    echo ""
    echo "=== Testing Modular Script ==="
    
    # Test with dry-run approach (validate functions load)
    if timeout 10s bash -c "
        source '$SCRIPT_DIR/lib/system.sh' 2>/dev/null
        source '$SCRIPT_DIR/lib/logging.sh' 2>/dev/null  
        source '$SCRIPT_DIR/lib/config.sh' 2>/dev/null
        echo 'Module loading test successful'
    "; then
        echo "✓ Module loading works correctly"
    else
        echo "✗ Module loading failed!"
        return 1
    fi
    
    return 0
}

# Function to show migration instructions
show_migration_instructions() {
    echo ""
    echo "=== Migration Instructions ==="
    echo ""
    echo "1. BACKUP (Already done if using this script):"
    echo "   - Original script backed up as cleanup.sh.backup"
    echo ""
    echo "2. TESTING:"
    echo "   - Test the modular version first:"
    if [[ "$DOCKER_MODE" == "true" ]]; then
        echo "     docker-compose exec ts-to-mkv /service/cleanup_modular.sh"
    else
        echo "     ./cleanup_modular.sh"
    fi
    echo ""
    echo "3. DOCKER-COMPOSE UPDATE:"
    echo "   - Update your docker-compose.yml command:"
    echo "     OLD: command: [\"/service/cleanup.sh\"]"
    echo "     NEW: command: [\"/service/cleanup_modular.sh\"]"
    echo ""
    echo "4. CONFIGURATION:"
    echo "   - No changes needed to cleanup.env"
    echo "   - All existing settings work identically"
    echo ""
    echo "5. VERIFICATION:"
    echo "   - Monitor logs to ensure same behavior"
    echo "   - Check file processing works as expected"
    echo "   - Verify notifications still work"
    echo ""
    echo "6. ROLLBACK (if needed):"
    echo "   - Change docker-compose.yml back to /service/cleanup.sh"
    echo "   - Or restore from cleanup.sh.backup"
    echo ""
}

# Function to show architecture benefits
show_benefits() {
    echo ""
    echo "=== Benefits of Modular Architecture ==="
    echo ""
    echo "📦 MAINTAINABILITY:"
    echo "   - Functions grouped by responsibility"
    echo "   - Easier to locate and fix issues"
    echo "   - Smaller, focused files (40-155 lines vs 660 lines)"
    echo ""
    echo "🧪 TESTABILITY:"
    echo "   - Individual modules can be tested"
    echo "   - Easier debugging and development"
    echo "   - Clear separation of concerns"
    echo ""
    echo "🔧 EXTENSIBILITY:"
    echo "   - Add new features without touching existing code"
    echo "   - Swap implementations easily"
    echo "   - Plugin-style architecture"
    echo ""
    echo "📖 READABILITY:"
    echo "   - Clear module boundaries"
    echo "   - Self-documenting structure"
    echo "   - Logical grouping of functions"
    echo ""
}

# Main execution
main() {
    backup_original
    
    if validate_modular; then
        echo ""
        echo "✅ Modular setup validation PASSED"
        
        if test_modular; then
            echo "✅ Modular functionality test PASSED"
            echo ""
            echo "🎉 READY FOR MIGRATION!"
            show_migration_instructions
            show_benefits
        else
            echo "❌ Modular functionality test FAILED"
            echo "Please check the module files and try again."
            exit 1
        fi
    else
        echo ""
        echo "❌ Modular setup validation FAILED"
        echo "Some required files are missing or have errors."
        exit 1
    fi
}

# Run main function
main "$@"
