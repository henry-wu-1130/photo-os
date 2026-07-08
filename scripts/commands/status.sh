#!/bin/sh
# commands/status.sh - Show a summary of the photo library
# Usage: photo status

cmd_status() {
    if [ ! -d "$PHOTO_ROOT" ]; then
        log_error "Photo library not found: $PHOTO_ROOT"
        log_info  "Set PHOTO_ROOT in $HOME/.photo-os/config"
        exit 1
    fi

    RAW_DIR="$PHOTO_ROOT/RAW"
    EXPORT_DIR="$PHOTO_ROOT/Export"
    PORTFOLIO_DIR="$PHOTO_ROOT/Portfolio"

    # Count sessions (leaf directories under RAW/)
    SESSION_COUNT=0
    if [ -d "$RAW_DIR" ]; then
        SESSION_COUNT=$(find "$RAW_DIR" -mindepth 2 -maxdepth 2 -type d | wc -l | tr -d ' ')
    fi

    # Count RAW files and compute size
    RAW_FILES=0
    RAW_SIZE="0"
    if [ -d "$RAW_DIR" ]; then
        RAW_FILES=$(find "$RAW_DIR" -iname "*.arw" | wc -l | tr -d ' ')
        RAW_SIZE=$(du -sh "$RAW_DIR" 2>/dev/null | cut -f1)
    fi

    # Count exports
    EXPORT_FILES=0
    EXPORT_SIZE="0"
    if [ -d "$EXPORT_DIR" ]; then
        EXPORT_FILES=$(find "$EXPORT_DIR" -iname "*.jpg" | wc -l | tr -d ' ')
        EXPORT_SIZE=$(du -sh "$EXPORT_DIR" 2>/dev/null | cut -f1)
    fi

    # Count portfolio images
    PORTFOLIO_FILES=0
    if [ -d "$PORTFOLIO_DIR" ]; then
        PORTFOLIO_FILES=$(find "$PORTFOLIO_DIR" -iname "*.jpg" | wc -l | tr -d ' ')
    fi

    # Find last imported session (most recently modified dir under RAW/)
    LAST_SESSION=""
    if [ -d "$RAW_DIR" ]; then
        LAST_SESSION=$(find "$RAW_DIR" -mindepth 2 -maxdepth 2 -type d \
            | xargs ls -dt 2>/dev/null | head -1 | xargs basename 2>/dev/null)
    fi

    # Find last backup entry
    LAST_BACKUP="never"
    BACKUP_LOG="$HOME/.photo-os/backup.log"
    if [ -f "$BACKUP_LOG" ]; then
        LAST_BACKUP=$(tail -1 "$BACKUP_LOG" | cut -d' ' -f1-2)
    fi

    printf '\n'
    printf 'Library:   %s\n' "$PHOTO_ROOT"
    printf 'Sessions:  %s\n' "$SESSION_COUNT"
    printf 'RAW files: %s (%s)\n' "$RAW_FILES" "${RAW_SIZE:-0}"
    printf 'Exports:   %s (%s)\n' "$EXPORT_FILES" "${EXPORT_SIZE:-0}"
    printf 'Portfolio: %s image(s)\n' "$PORTFOLIO_FILES"
    printf '\n'
    printf 'Last import: %s\n' "${LAST_SESSION:-none}"
    printf 'Last backup: %s\n' "$LAST_BACKUP"
    printf '\n'
    printf 'Backup primary:   %s\n' "${BACKUP_PRIMARY:-not configured}"
    printf 'Backup secondary: %s\n' "${BACKUP_SECONDARY:-not configured}"
    printf '\n'
}
