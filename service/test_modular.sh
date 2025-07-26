#!/bin/bash
# Test script for modular architecture validation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

echo "=== Testing Modular Architecture ==="

# Test 1: Module loading
echo "Test 1: Module Loading"
test_module_loading() {
    local modules=(
        "system.sh"
        "logging.sh"
        "config.sh"
        "video_analysis.sh"
        "encoding.sh"
        "file_processor.sh"
        "file_monitor.sh"
    )
    
    for module in "${modules[@]}"; do
        if [[ -f "$LIB_DIR/$module" ]]; then
            echo "✓ $module found"
        else
            echo "✗ $module missing"
            return 1
        fi
    done
    return 0
}

test_module_loading
if [[ $? -eq 0 ]]; then
    echo "✓ All modules present"
else
    echo "✗ Module loading test failed"
    exit 1
fi

# Test 2: Configuration loading
echo -e "\nTest 2: Configuration Loading"
source "$LIB_DIR/system.sh" 2>/dev/null || true
source "$LIB_DIR/logging.sh" 2>/dev/null || true
source "$LIB_DIR/config.sh" 2>/dev/null || true

# Mock the config file check for testing
if [[ -f "$SCRIPT_DIR/cleanup.env" ]]; then
    echo "✓ Configuration file exists"
else
    echo "✗ Configuration file missing"
fi

# Test 3: Function availability
echo -e "\nTest 3: Core Functions Available"
test_functions() {
    local functions=(
        "log_info"
        "log_warn"
        "log_error"
        "ntfy_send"
        "load_config"
        "check_dependencies"
    )
    
    for func in "${functions[@]}"; do
        if declare -f "$func" > /dev/null; then
            echo "✓ Function $func available"
        else
            echo "✗ Function $func missing"
            return 1
        fi
    done
    return 0
}

test_functions
if [[ $? -eq 0 ]]; then
    echo "✓ All core functions available"
else
    echo "✗ Function availability test failed"
fi

# Test 4: Syntax validation
echo -e "\nTest 4: Syntax Validation"
test_syntax() {
    local modules=(
        "$SCRIPT_DIR/cleanup_modular.sh"
        "$LIB_DIR/system.sh"
        "$LIB_DIR/logging.sh"
        "$LIB_DIR/config.sh"
        "$LIB_DIR/video_analysis.sh"
        "$LIB_DIR/encoding.sh"
        "$LIB_DIR/file_processor.sh"
        "$LIB_DIR/file_monitor.sh"
    )
    
    for module in "${modules[@]}"; do
        if bash -n "$module" 2>/dev/null; then
            echo "✓ $module syntax OK"
        else
            echo "✗ $module syntax error"
            return 1
        fi
    done
    return 0
}

test_syntax
if [[ $? -eq 0 ]]; then
    echo "✓ All modules have valid syntax"
else
    echo "✗ Syntax validation failed"
fi

echo -e "\n=== Module Architecture Summary ==="
echo "Main script: cleanup_modular.sh"
echo "Modules:"
for module in "$LIB_DIR"/*.sh; do
    if [[ -f "$module" ]]; then
        lines=$(wc -l < "$module")
        echo "  - $(basename "$module"): $lines lines"
    fi
done

total_lines=0
for module in "$LIB_DIR"/*.sh; do
    if [[ -f "$module" ]]; then
        lines=$(wc -l < "$module")
        total_lines=$((total_lines + lines))
    fi
done

main_lines=$(wc -l < "$SCRIPT_DIR/cleanup_modular.sh")
total_lines=$((total_lines + main_lines))

echo "  - cleanup_modular.sh: $main_lines lines"
echo "Total modular code: $total_lines lines"

if [[ -f "$SCRIPT_DIR/cleanup.sh" ]]; then
    original_lines=$(wc -l < "$SCRIPT_DIR/cleanup.sh")
    echo "Original monolithic: $original_lines lines"
    echo "Line difference: $((total_lines - original_lines)) lines"
fi

echo -e "\n=== Test Complete ==="
