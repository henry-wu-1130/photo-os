#!/bin/sh
# commands/import.sh - Import RAW files from a memory card or folder
# Usage: photo import <source_path> [--session "YYYY-MM-DD Location Theme"] [--dry-run] [--no-eject]

cmd_import() {
    SOURCE=""
    SESSION=""
    DRY_RUN=0
    NO_EJECT=0

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --session)
                SESSION="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --no-eject)
                NO_EJECT=1
                shift
                ;;
            -*)
                log_error "Unknown flag: $1"
                exit 1
                ;;
            *)
                if [ -z "$SOURCE" ]; then
                    SOURCE="$1"
                else
                    log_error "Unexpected argument: $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [ -z "$SOURCE" ]; then
        log_error "Source path required."
        log_info  "Usage: photo import <source_path> [--session \"YYYY-MM-DD Location Theme\"]"
        exit 1
    fi

    if [ ! -d "$SOURCE" ]; then
        log_error "Source not found or not a directory: $SOURCE"
        exit 1
    fi

    require_cmd rsync

    # Count .ARW files on source (case-insensitive)
    ARW_COUNT=$(find "$SOURCE" -iname "*.arw" | wc -l | tr -d ' ')

    if [ "$ARW_COUNT" -eq 0 ]; then
        log_error "No .ARW files found in: $SOURCE"
        exit 1
    fi

    log_info "Found $ARW_COUNT .ARW file(s) in $SOURCE"

    # Prompt for session name if not provided
    if [ -z "$SESSION" ]; then
        printf '[photo] Session name (YYYY-MM-DD Location Theme): '
        read -r SESSION
    fi

    validate_session "$SESSION"

    DEST="$(raw_path "$SESSION")"

    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "[dry-run] Would create: $DEST"
        log_info "[dry-run] Would copy $ARW_COUNT .ARW file(s) from $SOURCE"
        log_info "[dry-run] No files were copied."
        return 0
    fi

    # Create destination folder if needed
    if [ ! -d "$DEST" ]; then
        mkdir -p "$DEST"
        log_ok "Created session folder: $DEST"
    else
        log_info "Session folder exists: $DEST"
    fi

    log_info "Copying to $DEST ..."

    # Copy each .ARW file with checksum verification; skip existing identical files
    find "$SOURCE" -iname "*.arw" | while IFS= read -r f; do
        rsync -a --checksum --ignore-existing "$f" "$DEST/"
    done

    # Verify destination count
    DEST_COUNT=$(find "$DEST" -iname "*.arw" | wc -l | tr -d ' ')
    log_ok "Import complete: $DEST_COUNT / $ARW_COUNT file(s) in $DEST"

    # Append to import log
    LOG_FILE="$HOME/.photo-os/import.log"
    printf '%s  session="%s"  files=%s  source=%s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$SESSION" "$DEST_COUNT" "$SOURCE" \
        >> "$LOG_FILE"

    # Eject mounted volume (only if source is under /Volumes/)
    if [ "$NO_EJECT" -eq 0 ] && printf '%s' "$SOURCE" | grep -q '^/Volumes/'; then
        VOLUME=$(printf '%s\n' "$SOURCE" | cut -d/ -f1-3)
        log_info "Ejecting $VOLUME ..."
        diskutil eject "$VOLUME" && log_ok "Ejected $VOLUME" \
            || log_info "Could not eject — eject manually."
    fi
}
