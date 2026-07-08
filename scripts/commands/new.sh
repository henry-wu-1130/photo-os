#!/bin/sh
# commands/new.sh - Create a new shoot session folder structure
# Usage: photo new "YYYY-MM-DD Location Theme"
#
# Creates (idempotent — safe to run twice):
#   RAW/YYYY/YYYY-MM-DD Location Theme/
#   Export/YYYY-MM-DD Location Theme/web/
#   Export/YYYY-MM-DD Location Theme/print/
#   Portfolio/YYYY-MM-DD Location Theme/
# Copies templates/session-notes.md into the RAW folder if not already present.

cmd_new() {
    session="${1:-}"

    if [ -z "$session" ]; then
        log_error "Session name required."
        log_info  "Usage: photo new \"YYYY-MM-DD Location Theme\""
        exit 1
    fi

    validate_session "$session"

    raw_dir="$(raw_path "$session")"
    export_web="$(export_path "$session" web)"
    export_print="$(export_path "$session" print)"
    portfolio_dir="$(portfolio_path "$session")"

    # Create all directories (mkdir -p is idempotent)
    mkdir -p "$raw_dir" "$export_web" "$export_print" "$portfolio_dir"

    log_ok "RAW:       $raw_dir"
    log_ok "Export:    $(export_path "$session") (web/ print/)"
    log_ok "Portfolio: $portfolio_dir"

    # Copy session notes template if the template exists and destination does not
    notes_src="$SCRIPT_DIR/../templates/session-notes.md"
    notes_dest="$raw_dir/session-notes.md"

    if [ -f "$notes_src" ] && [ ! -f "$notes_dest" ]; then
        cp "$notes_src" "$notes_dest"
        log_ok "Notes:     $notes_dest"
    fi
}
