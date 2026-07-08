#!/bin/sh
# commands/current.sh - Show paths for the current session
# Usage: photo current

cmd_current() {
    session_require
    session="$CURRENT_SESSION"

    printf '\n'
    printf 'Session:   %s\n' "$session"
    printf '\n'
    printf 'RAW:       %s\n' "$(raw_path "$session")"
    printf 'Export:    %s\n' "$(export_path "$session")"
    printf 'Portfolio: %s\n' "$(portfolio_path "$session")"
    printf '\n'
    printf 'Export web path (paste into darktable):\n'
    printf '  %s\n' "$(export_path "$session" web)"
    printf '\n'
}
