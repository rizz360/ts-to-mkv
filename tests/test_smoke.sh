#!/bin/bash
# Lightweight integration smoke test for modular file processing flow

set -euo pipefail

if (( BASH_VERSINFO[0] < 4 )); then
    echo "Skipping smoke test: requires Bash 4+ (current: $BASH_VERSION)"
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

INPUT_DIR="$WORK_DIR/input"
OUTPUT_DIR="$WORK_DIR/output"
LOG_DIR="$WORK_DIR/logs"
TEMP_DIR="$WORK_DIR/tmp"

mkdir -p "$INPUT_DIR/sub" "$OUTPUT_DIR" "$LOG_DIR" "$TEMP_DIR"

# Provide required globals used by file_processor.sh
DELETE_TS=false
DELETE_SKIPPED_TS=false
DELETE_SKIPPED_VERIFY_DURATION=false
DELETE_SKIPPED_DURATION_TOLERANCE_PCT=2.5
DELETE_SKIPPED_DURATION_TOLERANCE_SEC=120
CLEANUP_TEMP_ON_FAILURE=true

log_info() { :; }
log_warn() { :; }
log_error() { :; }
ntfy_send() { :; }

get_video_info() {
    local _file="$1"
    local -n info_ref="$2"
    info_ref[size_gb]=1
    info_ref[res_label]=720p
    info_ref[video_codec]=h264
    info_ref[video_bitrate]=4000000
    info_ref[duration]=60
}

# Force remux path for deterministic behavior.
should_encode() {
    return 1
}

remux_file() {
    local input_file="$1"
    local output_path="$2"
    cp "$input_file" "$output_path"
}

encode_file() {
    local input_file="$1"
    local output_path="$2"
    cp "$input_file" "$output_path"
}

source "$ROOT_DIR/app/lib/file_processor.sh"

# Case 1: Keep source file and create expected output path.
printf "smoke-data-1" > "$INPUT_DIR/sub/sample.ts"
process_file "$INPUT_DIR/sub/sample.ts"

EXPECTED_OUTPUT_1="$OUTPUT_DIR/sub/sample.TV.720p.mkv"
if [[ ! -f "$EXPECTED_OUTPUT_1" ]]; then
    echo "Smoke test failed: expected output missing: $EXPECTED_OUTPUT_1"
    exit 1
fi

if ! grep -Fxq "$INPUT_DIR/sub/sample.ts" "$LOG_DIR/done.log"; then
    echo "Smoke test failed: done.log missing processed file entry"
    exit 1
fi

if [[ ! -f "$INPUT_DIR/sub/sample.ts" ]]; then
    echo "Smoke test failed: source should be preserved when DELETE_TS=false"
    exit 1
fi

# Case 2: Delete source file when configured.
DELETE_TS=true
printf "smoke-data-2" > "$INPUT_DIR/sub/delete_me.ts"
process_file "$INPUT_DIR/sub/delete_me.ts"

EXPECTED_OUTPUT_2="$OUTPUT_DIR/sub/delete_me.TV.720p.mkv"
if [[ ! -f "$EXPECTED_OUTPUT_2" ]]; then
    echo "Smoke test failed: expected delete-case output missing: $EXPECTED_OUTPUT_2"
    exit 1
fi

if [[ -f "$INPUT_DIR/sub/delete_me.ts" ]]; then
    echo "Smoke test failed: source should be deleted when DELETE_TS=true"
    exit 1
fi

# Case 3: Delete skipped source when expected output already exists and safeguard passes.
DELETE_TS=false
DELETE_SKIPPED_TS=true
printf "smoke-data-3" > "$INPUT_DIR/sub/skip_delete.ts"
printf "already-converted" > "$OUTPUT_DIR/sub/skip_delete.TV.720p.mkv"
process_file "$INPUT_DIR/sub/skip_delete.ts"

if [[ -f "$INPUT_DIR/sub/skip_delete.ts" ]]; then
    echo "Smoke test failed: skipped source should be deleted when DELETE_SKIPPED_TS=true and expected output exists"
    exit 1
fi

# Case 4: Keep skipped source when expected output is empty (safeguard).
printf "smoke-data-4" > "$INPUT_DIR/sub/skip_keep.ts"
: > "$OUTPUT_DIR/sub/skip_keep.TV.720p.mkv"
process_file "$INPUT_DIR/sub/skip_keep.ts"

if [[ ! -f "$INPUT_DIR/sub/skip_keep.ts" ]]; then
    echo "Smoke test failed: skipped source should be preserved when expected output is empty"
    exit 1
fi

# Case 5: Preserve deep show/season folder structure.
mkdir -p "$INPUT_DIR/shows/Example Show/SEASON 01"
printf "smoke-data-5" > "$INPUT_DIR/shows/Example Show/SEASON 01/Some Random Recording S01E02.ts"
process_file "$INPUT_DIR/shows/Example Show/SEASON 01/Some Random Recording S01E02.ts"

EXPECTED_OUTPUT_3="$OUTPUT_DIR/shows/Example Show/SEASON 01/Some Random Recording S01E02.TV.720p.mkv"
if [[ ! -f "$EXPECTED_OUTPUT_3" ]]; then
    echo "Smoke test failed: expected nested show output missing: $EXPECTED_OUTPUT_3"
    exit 1
fi

# Case 6: Temp job directory generation must be unique for same basename in different paths.
temp_a="$(create_temp_job_dir "shows/Series A/SEASON 01/Episode S01E01")"
temp_b="$(create_temp_job_dir "shows/Series B/SEASON 01/Episode S01E01")"

if [[ "$temp_a" == "$temp_b" ]]; then
    echo "Smoke test failed: temp directories should be unique per job"
    exit 1
fi

rm -rf "$temp_a" "$temp_b"

echo "Smoke test passed"
