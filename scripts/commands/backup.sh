#!/bin/sh
# commands/backup.sh - Sync photo library to backup destinations
# Usage: photo backup [--dest primary|secondary|all] [--dry-run] [--verify]

cmd_backup() {
    DEST_TARGET="all"
    DRY_RUN=0
    VERIFY=0

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --dest)
                DEST_TARGET="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --verify)
                VERIFY=1
                shift
                ;;
            -*)
                log_error "Unknown flag: $1"
                exit 1
                ;;
            *)
                log_error "Unexpected argument: $1"
                exit 1
                ;;
        esac
    done

    case "$DEST_TARGET" in
        primary|secondary|all) ;;
        *)
            log_error "Invalid --dest value: $DEST_TARGET (expected: primary, secondary, all)"
            exit 1
            ;;
    esac

    require_cmd rsync

    ran=0

    if [ "$DEST_TARGET" = "primary" ] || [ "$DEST_TARGET" = "all" ]; then
        _run_backup "$BACKUP_PRIMARY" "primary" "$DRY_RUN" "$VERIFY"
        ran=1
    fi

    if [ "$DEST_TARGET" = "secondary" ] || [ "$DEST_TARGET" = "all" ]; then
        _run_backup "$BACKUP_SECONDARY" "secondary" "$DRY_RUN" "$VERIFY"
        ran=1
    fi

    if [ "$ran" -eq 0 ]; then
        log_error "No backup destinations configured."
        log_info  "Edit $HOME/.photo-os/config and set BACKUP_PRIMARY or BACKUP_SECONDARY."
        exit 1
    fi
}

_run_backup() {
    dest="$1"
    label="$2"
    dry_run="$3"
    verify="$4"

    if [ -z "$dest" ]; then
        log_info "Skipping $label backup — not configured in $HOME/.photo-os/config"
        return 0
    fi

    log_info "Backing up to $label: $dest"

    RSYNC_FLAGS="-av --checksum"

    if [ "$dry_run" -eq 1 ]; then
        RSYNC_FLAGS="$RSYNC_FLAGS --dry-run"
        log_info "[dry-run] Would sync $PHOTO_ROOT → $dest"
    fi

    # Never delete from destination — backup is append-only
    # shellcheck disable=SC2086
    rsync $RSYNC_FLAGS "$PHOTO_ROOT/" "$dest/"

    if [ "$verify" -eq 1 ] && [ "$dry_run" -eq 0 ]; then
        log_info "Verifying checksums ..."
        rsync -av --checksum --dry-run "$PHOTO_ROOT/" "$dest/" \
            | grep -v "^\." | grep -v "^sending" | grep -v "^total" \
            | grep -v "/$" \
            && log_ok "Verification complete — $label backup is consistent." \
            || log_error "Verification found differences — check manually."
    fi

    if [ "$dry_run" -eq 0 ]; then
        # Log the backup event
        LOG_FILE="$HOME/.photo-os/backup.log"
        printf '%s  dest=%s  path=%s\n' \
            "$(date '+%Y-%m-%d %H:%M:%S')" "$label" "$dest" \
            >> "$LOG_FILE"
        log_ok "Backup to $label complete."
    fi
}
