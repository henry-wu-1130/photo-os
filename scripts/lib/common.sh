#!/bin/sh
# common.sh - shared utility functions for photo-os scripts
# Source this file; do not execute directly.

# ─── Config ────────────────────────────────────────────────────────────────

PHOTO_OS_CONFIG_DIR="$HOME/.photo-os"
PHOTO_OS_CONFIG="$PHOTO_OS_CONFIG_DIR/config"

config_init() {
    if [ ! -f "$PHOTO_OS_CONFIG" ]; then
        mkdir -p "$PHOTO_OS_CONFIG_DIR"
        cat > "$PHOTO_OS_CONFIG" <<EOF
# photo-os configuration
# Edit this file to match your setup.

PHOTO_ROOT="\$HOME/Photography"
BACKUP_PRIMARY=""   # e.g. /Volumes/BackupDrive/Photography
BACKUP_SECONDARY="" # e.g. rclone remote or second drive
EOF
        log_info "Created config at $PHOTO_OS_CONFIG — please review it."
    fi
    # shellcheck source=/dev/null
    . "$PHOTO_OS_CONFIG"
}

# ─── Logging ───────────────────────────────────────────────────────────────

log_info() {
    printf '[photo] %s\n' "$*"
}

log_error() {
    printf '[photo] ERROR: %s\n' "$*" >&2
}

log_ok() {
    printf '[photo] ✓ %s\n' "$*"
}

# ─── Session Helpers ───────────────────────────────────────────────────────

# Extract YYYY from a session name "YYYY-MM-DD Location Theme"
session_year() {
    printf '%s\n' "$1" | cut -c1-4
}

# Resolve RAW path for a session
raw_path() {
    session="$1"
    year=$(session_year "$session")
    printf '%s\n' "${PHOTO_ROOT}/RAW/${year}/${session}"
}

# Resolve Export path for a session (optionally include preset subfolder)
export_path() {
    session="$1"
    preset="${2:-}"
    if [ -n "$preset" ]; then
        printf '%s\n' "${PHOTO_ROOT}/Export/${session}/${preset}"
    else
        printf '%s\n' "${PHOTO_ROOT}/Export/${session}"
    fi
}

# Resolve Portfolio path for a session
portfolio_path() {
    session="$1"
    printf '%s\n' "${PHOTO_ROOT}/Portfolio/${session}"
}

# Validate session name format: "YYYY-MM-DD anything"
validate_session() {
    session="$1"
    if ! printf '%s\n' "$session" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2} .+'; then
        log_error "Invalid session name: '$session'"
        log_error "Expected format: 'YYYY-MM-DD Location Theme'"
        exit 1
    fi
}

# ─── System Checks ─────────────────────────────────────────────────────────

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        log_error "Required command not found: $1"
        exit 1
    fi
}
