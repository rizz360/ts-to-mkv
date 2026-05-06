#!/bin/bash
# Safety and regression checks for modular-only architecture

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$ROOT_DIR/app"
LIB_DIR="$APP_DIR/lib"

check_deps() {
    local missing=()
    for cmd in "$@"; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        printf "[FAIL] Missing required tools: %s\n" "${missing[*]}"
        exit 1
    fi
}

check_deps rg bash

pass() {
    printf "[PASS] %s\n" "$1"
}

fail() {
    printf "[FAIL] %s\n" "$1"
    exit 1
}

assert_file_exists() {
    local file="$1"
    [[ -f "$file" ]] || fail "Missing required file: $file"
}

assert_file_absent() {
    local file="$1"
    [[ ! -e "$file" ]] || fail "Legacy artifact should not exist: $file"
}

assert_no_pattern() {
    local pattern="$1"
    local scope="$2"
    if rg -n "$pattern" $scope >/dev/null 2>&1; then
        fail "Found forbidden pattern: $pattern"
    fi
}

echo "=== Safety Checks (Modular-Only) ==="

# 1) Required runtime files
assert_file_exists "$APP_DIR/entrypoint.sh"
assert_file_exists "$LIB_DIR/system.sh"
assert_file_exists "$LIB_DIR/logging.sh"
assert_file_exists "$LIB_DIR/config.sh"
assert_file_exists "$LIB_DIR/video_analysis.sh"
assert_file_exists "$LIB_DIR/encoding.sh"
assert_file_exists "$LIB_DIR/file_processor.sh"
assert_file_exists "$LIB_DIR/file_monitor.sh"
assert_file_exists "$ROOT_DIR/docker-compose.yml"
assert_file_exists "$ROOT_DIR/Dockerfile"
pass "Required modular files exist"

# 2) Legacy artifacts must be gone
assert_file_absent "$ROOT_DIR/service"
pass "Legacy files are removed"

# 3) Runtime must point to modular entrypoint
if ! rg -n '^ENTRYPOINT \["/app/entrypoint\.sh"\]' "$ROOT_DIR/Dockerfile" >/dev/null; then
    fail "Dockerfile ENTRYPOINT is not modular"
fi
if rg -n "entrypoint:\s*/service/" "$ROOT_DIR/docker-compose.yml" >/dev/null; then
    fail "docker-compose still references old service paths"
fi
pass "Image entrypoint is modular"

# 4) Strict-mode shell footguns must not be present
assert_no_pattern "grep '\\.ts\\$' \| head -n1" "$APP_DIR/entrypoint.sh $LIB_DIR"
assert_no_pattern "\(\(new_files\+\+\)\)|\(\(job_count\+\+\)\)" "$APP_DIR/entrypoint.sh $LIB_DIR"
pass "Strict-mode footgun patterns not found"

# 5) Syntax checks
bash -n "$APP_DIR/entrypoint.sh"
for file in "$LIB_DIR"/*.sh; do
    bash -n "$file"
done
pass "Bash syntax checks passed"

# 6) Documentation must not present legacy as current option
assert_no_pattern "entrypoint:\s*/service/cleanup\.sh" "$ROOT_DIR/README.md $ROOT_DIR/docs/DOCKER.md"
pass "Docs do not advertise legacy entrypoint"

echo "=== Safety Checks Complete ==="
