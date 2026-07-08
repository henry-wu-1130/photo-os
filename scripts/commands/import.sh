#!/bin/sh
# commands/import.sh - Import RAW files from a camera SD card or folder
# Usage: photo import [source_path] [--session "YYYY-MM-DD Project"] [--dry-run] [--no-eject]
#
# When source_path is omitted, camera cards are detected automatically by
# scanning /Volumes for directories that contain a DCIM subfolder.

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

    # ── Source detection ──────────────────────────────────────────────────────

    if [ -z "$SOURCE" ]; then
        SOURCE="$(_detect_camera_card)"
    fi

    if [ ! -d "$SOURCE" ]; then
        log_error "Source not found or not a directory: $SOURCE"
        exit 1
    fi

    require_cmd rsync

    # ── Count RAW files ───────────────────────────────────────────────────────

    ARW_COUNT=$(find "$SOURCE" -iname "*.arw" | wc -l | tr -d ' ')

    if [ "$ARW_COUNT" -eq 0 ]; then
        log_error "No .ARW files found in: $SOURCE"
        exit 1
    fi

    log_info "Found $ARW_COUNT .ARW file(s) in $SOURCE"

    # ── Resolve session name ──────────────────────────────────────────────────

    if [ -z "$SESSION" ]; then
        SESSION="$(_resolve_session)"
    fi

    validate_session "$SESSION"

    # ── Dry run ───────────────────────────────────────────────────────────────

    DEST="$(raw_path "$SESSION")"

    if [ "$DRY_RUN" -eq 1 ]; then
        log_info "[dry-run] Session: $SESSION"
        log_info "[dry-run] Would copy $ARW_COUNT .ARW file(s) to $DEST"
        log_info "[dry-run] No files were copied."
        return 0
    fi

    # ── Create session if needed ──────────────────────────────────────────────

    if [ ! -d "$DEST" ]; then
        # cmd_new also calls session_save, so no need to call it again below.
        . "$CMD_DIR/new.sh"
        cmd_new "$SESSION"
    else
        log_info "Using existing session: $SESSION"
        session_save "$SESSION"
    fi

    # ── Copy files ────────────────────────────────────────────────────────────

    log_info "Copying to $DEST ..."

    find "$SOURCE" -iname "*.arw" | while IFS= read -r f; do
        rsync -a --checksum --ignore-existing "$f" "$DEST/"
    done

    DEST_COUNT=$(find "$DEST" -iname "*.arw" | wc -l | tr -d ' ')
    log_ok "Import complete: $DEST_COUNT / $ARW_COUNT file(s) in $DEST"

    # ── Log ───────────────────────────────────────────────────────────────────

    LOG_FILE="$HOME/.photo-os/import.log"
    printf '%s  session="%s"  files=%s  source=%s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$SESSION" "$DEST_COUNT" "$SOURCE" \
        >> "$LOG_FILE"

    # ── Eject ────────────────────────────────────────────────────────────────

    if [ "$NO_EJECT" -eq 0 ] && printf '%s' "$SOURCE" | grep -q '^/Volumes/'; then
        VOLUME=$(printf '%s\n' "$SOURCE" | cut -d/ -f1-3)
        log_info "Ejecting $VOLUME ..."
        diskutil eject "$VOLUME" && log_ok "Ejected $VOLUME" \
            || log_info "Could not eject — eject manually."
    fi
}

# ── Camera card detection ─────────────────────────────────────────────────────
# Scans /Volumes for directories containing a DCIM subfolder.
# Returns the volume path via stdout; user interaction goes to stderr.

_detect_camera_card() {
    # A volume is a camera card if and only if it has a DCIM directory.
    # find at depth 2 gives us: /Volumes/<name>/DCIM
    cards=$(find /Volumes -maxdepth 2 -mindepth 2 -type d -name "DCIM" 2>/dev/null \
        | sed 's|/DCIM$||' \
        | sort)

    if [ -z "$cards" ]; then
        printf '[photo] No camera SD card detected.\n' >&2
        printf '[photo] Please insert a camera SD card and try again.\n' >&2
        printf '[photo] Or specify a path manually: photo import <path>\n' >&2
        exit 1
    fi

    count=$(printf '%s\n' "$cards" | wc -l | tr -d ' ')

    if [ "$count" -eq 1 ]; then
        # Case A: exactly one card — use it automatically
        printf '[photo] ✓ Camera card detected\n' >&2
        printf '[photo]   Source: %s\n' "$cards" >&2
        printf '%s\n' "$cards"
        return 0
    fi

    # Case B: multiple cards — show a numbered menu
    printf '[photo] Multiple camera cards detected:\n' >&2
    i=1
    printf '%s\n' "$cards" | while IFS= read -r vol; do
        printf '  %d) %s\n' "$i" "$vol" >&2
        i=$((i + 1))
    done
    printf '[photo] Choose [1-%d]: ' "$count" >&2
    read -r answer

    chosen=$(printf '%s\n' "$cards" | sed -n "${answer}p")
    if [ -z "$chosen" ]; then
        printf '[photo] ERROR: Invalid choice.\n' >&2
        exit 1
    fi
    printf '%s\n' "$chosen"
}

# ── Session resolution ────────────────────────────────────────────────────────
# Returns a session name via stdout. All user prompts go to stderr.

_resolve_session() {
    today="$(date '+%Y-%m-%d')"
    raw_year_dir="$PHOTO_ROOT/RAW/$(printf '%s' "$today" | cut -c1-4)"

    # Look for existing sessions that start with today's date
    existing=""
    if [ -d "$raw_year_dir" ]; then
        existing=$(find "$raw_year_dir" -maxdepth 1 -mindepth 1 -type d \
            -name "${today} *" 2>/dev/null | sort)
    fi

    if [ -n "$existing" ]; then
        count=$(printf '%s\n' "$existing" | wc -l | tr -d ' ')

        if [ "$count" -eq 1 ]; then
            found=$(basename "$existing")
            printf '[photo] Existing session for today: %s\n' "$found" >&2
            printf '[photo] Reuse it? [Y/n] ' >&2
            read -r answer
            case "$answer" in
                n|N) : ;;  # fall through to prompt for new name
                *)   printf '%s\n' "$found"; return 0 ;;
            esac
        else
            # Multiple sessions today — list them and ask
            printf '[photo] Multiple sessions found for today:\n' >&2
            i=1
            printf '%s\n' "$existing" | while IFS= read -r d; do
                printf '  %d) %s\n' "$i" "$(basename "$d")" >&2
                i=$((i + 1))
            done
            printf '  n) Create a new session\n' >&2
            printf '[photo] Choose [1-%d / n]: ' "$count" >&2
            read -r answer
            case "$answer" in
                n|N) : ;;  # fall through to prompt for new name
                *)
                    chosen=$(printf '%s\n' "$existing" | sed -n "${answer}p")
                    if [ -n "$chosen" ]; then
                        printf '%s\n' "$(basename "$chosen")"
                        return 0
                    fi
                    ;;
            esac
        fi
    fi

    # Prompt for project name only; date is added automatically
    printf '[photo] Project name: ' >&2
    read -r project_name

    if [ -z "$project_name" ]; then
        printf '[photo] ERROR: Project name cannot be empty.\n' >&2
        exit 1
    fi

    printf '%s %s\n' "$today" "$project_name"
}
