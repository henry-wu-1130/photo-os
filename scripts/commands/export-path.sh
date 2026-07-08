#!/bin/sh
# commands/export-path.sh - Print the current session's web export path
# Usage: photo export-path
#
# Output is clean stdout (no [photo] prefix) — safe for shell substitution
# or direct copy-paste into darktable's export destination field.

cmd_export_path() {
    session_require
    export_path "$CURRENT_SESSION" web
}
