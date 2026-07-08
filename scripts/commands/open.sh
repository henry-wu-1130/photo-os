#!/bin/sh
# commands/open.sh - Open a session folder in Finder
# Usage: photo open <raw|export|portfolio>

cmd_open() {
    target="${1:-}"

    case "$target" in
        raw|export|portfolio) ;;
        "")
            log_error "Target required: raw, export, or portfolio"
            log_info  "Usage: photo open <raw|export|portfolio>"
            exit 1
            ;;
        *)
            log_error "Unknown target: '$target'"
            log_info  "Usage: photo open <raw|export|portfolio>"
            exit 1
            ;;
    esac

    session_require
    session="$CURRENT_SESSION"

    case "$target" in
        raw)       folder="$(raw_path "$session")" ;;
        export)    folder="$(export_path "$session" web)" ;;
        portfolio) folder="$(portfolio_path "$session")" ;;
    esac

    if [ ! -d "$folder" ]; then
        log_error "Folder does not exist: $folder"
        log_info  "Run 'photo new' or 'photo import' to create the session structure."
        exit 1
    fi

    open "$folder"
    log_ok "Opened $target: $folder"
}
