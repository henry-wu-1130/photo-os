#!/bin/sh
# commands/new.sh - Create a new shoot session folder
# Usage: photo new "YYYY-MM-DD Location Theme"

cmd_new() {
    session="${1:-}"

    if [ -z "$session" ]; then
        log_error "Session name required."
        log_info  "Usage: photo new \"YYYY-MM-DD Location Theme\""
        exit 1
    fi

    validate_session "$session"

    dest="$(raw_path "$session")"

    if [ -d "$dest" ]; then
        log_error "Session already exists: $dest"
        exit 1
    fi

    mkdir -p "$dest"
    log_ok "Created session: $dest"
}
