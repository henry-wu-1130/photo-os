#!/bin/sh
# commands/export.sh - Batch export all RAW files in the current session
# Usage: photo export [web|print] [--dry-run]
#
# Exports every .ARW file found in the current session's RAW directory.
# No rating filter. Cull unwanted files in digiKam before running this.
#
# If a .xmp sidecar exists alongside a .ARW, darktable-cli applies the
# full edit history automatically. Files without a sidecar are exported
# with darktable's default processing pipeline.

_DARKTABLE_CLI=""   # resolved once in cmd_export; shared by _run_export

cmd_export() {
    PRESET="web"
    DRY_RUN=0

    # ── Parse arguments ───────────────────────────────────────────────────────

    while [ $# -gt 0 ]; do
        case "$1" in
            web|print) PRESET="$1"; shift ;;
            --dry-run) DRY_RUN=1;   shift ;;
            -*)
                log_error "Unknown flag: $1"
                log_info  "Usage: photo export [web|print] [--dry-run]"
                exit 1
                ;;
            *)
                log_error "Unexpected argument: $1"
                exit 1
                ;;
        esac
    done

    # ── Locate darktable-cli ──────────────────────────────────────────────────

    _DARKTABLE_CLI="$(_find_darktable_cli)"
    if [ -z "$_DARKTABLE_CLI" ]; then
        log_error "darktable-cli not found."
        log_info  "macOS: /Applications/darktable.app/Contents/MacOS/darktable-cli"
        log_info  "Or add darktable-cli to your PATH."
        exit 1
    fi

    # ── Session ───────────────────────────────────────────────────────────────

    session_require
    SESSION="$CURRENT_SESSION"
    RAW_DIR="$(raw_path "$SESSION")"
    OUT_DIR="$(export_path "$SESSION" "$PRESET")"

    if [ ! -d "$RAW_DIR" ]; then
        log_error "RAW directory not found: $RAW_DIR"
        log_info  "Run 'photo import' first."
        exit 1
    fi

    # ── Collect files ─────────────────────────────────────────────────────────
    # Write the sorted list to a temp file so Phase 2 can iterate in the main
    # shell (not a subshell) and update CURRENT / FAILED counters correctly.

    TMP_LIST="$(mktemp /tmp/photo-export.XXXXXX)"
    trap 'rm -f "$TMP_LIST"' EXIT INT TERM

    find "$RAW_DIR" -maxdepth 1 -iname "*.arw" | sort > "$TMP_LIST"
    TOTAL=$(wc -l < "$TMP_LIST" | tr -d ' ')

    # ── Header ────────────────────────────────────────────────────────────────

    printf '\n'
    printf 'Current Session\n\n'
    printf '  %s\n\n' "$SESSION"
    printf 'Found\n\n'
    printf '  %s RAW file(s)\n\n' "$TOTAL"
    printf 'Export target\n\n'
    printf '  %s\n\n' "$OUT_DIR"

    if [ "$TOTAL" -eq 0 ]; then
        printf 'Nothing to export.\n\n'
        rm -f "$TMP_LIST"
        return 0
    fi

    # ── Dry run ───────────────────────────────────────────────────────────────

    if [ "$DRY_RUN" -eq 1 ]; then
        printf 'Dry run — no files will be exported.\n\n'
        while IFS= read -r raw; do
            printf '  %s\n' "$(basename "$raw")"
        done < "$TMP_LIST"
        printf '\n'
        rm -f "$TMP_LIST"
        return 0
    fi

    # ── Export ────────────────────────────────────────────────────────────────

    mkdir -p "$OUT_DIR"
    printf 'Exporting...\n\n'

    CURRENT=0
    FAILED=0

    while IFS= read -r raw; do
        if _run_export "$raw" "$OUT_DIR" "$PRESET"; then
            :
        else
            FAILED=$((FAILED + 1))
        fi
        CURRENT=$((CURRENT + 1))
        _draw_progress "$CURRENT" "$TOTAL"
    done < "$TMP_LIST"

    printf '\n\n'
    rm -f "$TMP_LIST"

    # ── Summary ───────────────────────────────────────────────────────────────

    SUCCEEDED=$((TOTAL - FAILED))
    if [ "$FAILED" -eq 0 ]; then
        printf 'Done.\n\n'
        printf '  %d image(s) → %s\n\n' "$SUCCEEDED" "$OUT_DIR"
    else
        printf 'Done with errors.\n\n'
        printf '  %d exported, %d failed → %s\n\n' "$SUCCEEDED" "$FAILED" "$OUT_DIR"
    fi
}

# ── Helpers ───────────────────────────────────────────────────────────────────

# Draw an in-place ASCII progress bar using carriage return.
# Output stays on the same terminal line until the final newline after the loop.
_draw_progress() {
    current="$1"
    total="$2"
    bar_width=20

    if [ "$total" -gt 0 ]; then
        filled=$((current * bar_width / total))
    else
        filled=0
    fi
    empty=$((bar_width - filled))

    bar=""
    i=0
    while [ "$i" -lt "$filled" ]; do bar="${bar}█"; i=$((i + 1)); done
    while [ "$i" -lt "$bar_width" ]; do bar="${bar}░"; i=$((i + 1)); done

    printf '\r%s  %d / %d' "$bar" "$current" "$total"
}

# Locate darktable-cli: PATH first, then the standard macOS app bundle.
_find_darktable_cli() {
    if command -v darktable-cli >/dev/null 2>&1; then
        command -v darktable-cli
        return
    fi
    if [ -x "/Applications/darktable.app/Contents/MacOS/darktable-cli" ]; then
        printf '/Applications/darktable.app/Contents/MacOS/darktable-cli\n'
        return
    fi
}

# Export one RAW file with darktable-cli.
# darktable-cli automatically detects and applies the .xmp sidecar if it exists.
# Returns 0 on success, non-zero on failure.
_run_export() {
    raw="$1"
    out_dir="$2"
    preset="$3"

    case "$preset" in
        web)
            "$_DARKTABLE_CLI" "$raw" "$out_dir" \
                --out-ext jpg \
                --icc-type SRGB \
                --width 1920 --height 1920 \
                --hq true \
                >/dev/null 2>&1
            ;;
        print)
            "$_DARKTABLE_CLI" "$raw" "$out_dir" \
                --out-ext jpg \
                --icc-type ADOBERGB \
                --hq true \
                >/dev/null 2>&1
            ;;
    esac
}
