#!/bin/sh
# commands/export.sh - Export ★5 photos from the current session using darktable-cli
# Usage: photo export [web|print] [--rating N] [--dry-run]
#
# How it works:
#   1. Reads the current session.
#   2. Finds all .ARW files in the session's RAW directory.
#   3. For each .ARW, reads xmp:Rating from the sidecar .xmp file.
#   4. Exports only images rated ★N or above (default: ★5) using darktable-cli.
#   5. Output lands in Export/<session>/web/ or print/.
#
# The export trigger is the xmp:Rating field — not the existence of a .xmp file.
# Rating is set in digiKam (or darktable lighttable) and stored in the .xmp sidecar.
# darktable-cli applies the full edit history from the same .xmp when exporting.

_DARKTABLE_CLI=""   # set by cmd_export; used by _run_darktable_export

cmd_export() {
    PRESET="web"
    MIN_RATING=5
    DRY_RUN=0

    # ── Parse arguments ───────────────────────────────────────────────────────

    while [ $# -gt 0 ]; do
        case "$1" in
            web|print)
                PRESET="$1"
                shift
                ;;
            --rating)
                MIN_RATING="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            -*)
                log_error "Unknown flag: $1"
                log_info  "Usage: photo export [web|print] [--rating N] [--dry-run]"
                exit 1
                ;;
            *)
                log_error "Unexpected argument: $1"
                exit 1
                ;;
        esac
    done

    case "$MIN_RATING" in
        [1-5]) ;;
        *)
            log_error "Invalid --rating value: '$MIN_RATING' (expected 1–5)"
            exit 1
            ;;
    esac

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

    log_info "Session: $SESSION"
    log_info "Filter:  ★${MIN_RATING}+ (set in digiKam)"
    log_info "Output:  $OUT_DIR"
    printf '\n'

    # ── Phase 1: select images by rating ─────────────────────────────────────
    #
    # Runs in a pipeline subshell; results are written to a temp file so that
    # Phase 2 can update counters in the main shell without subshell scoping.

    tmp_list="$(mktemp /tmp/photo-export.XXXXXX)"
    trap 'rm -f "$tmp_list"' EXIT INT TERM

    find "$RAW_DIR" -maxdepth 1 -iname "*.arw" | sort | while IFS= read -r raw; do
        xmp="$(_find_xmp "$raw")"
        [ -n "$xmp" ] || continue                          # no sidecar → not rated

        rating="$(_xmp_rating "$xmp")"
        [ -n "$rating" ] || continue                       # no rating field → skip
        [ "$rating" -ge "$MIN_RATING" ] 2>/dev/null || continue  # below threshold → skip

        printf '%s\n' "$raw" >> "$tmp_list"
    done

    SELECTED=$(wc -l < "$tmp_list" | tr -d ' ')

    if [ "$SELECTED" -eq 0 ]; then
        log_info "No images rated ★${MIN_RATING}+ found in this session."
        log_info "Rate images in digiKam (★5 = ready to export), then run:"
        log_info "  photo export $PRESET"
        rm -f "$tmp_list"
        return 0
    fi

    log_info "Found $SELECTED image(s) rated ★${MIN_RATING}+"
    printf '\n'

    # ── Dry run ───────────────────────────────────────────────────────────────

    if [ "$DRY_RUN" -eq 1 ]; then
        while IFS= read -r raw; do
            xmp="$(_find_xmp "$raw")"
            rating="$(_xmp_rating "$xmp")"
            log_info "[dry-run] ★${rating}  $(basename "$raw")"
        done < "$tmp_list"
        printf '\n'
        log_info "[dry-run] Would export $SELECTED file(s) to $OUT_DIR"
        rm -f "$tmp_list"
        return 0
    fi

    # ── Phase 2: export ───────────────────────────────────────────────────────

    mkdir -p "$OUT_DIR"

    EXPORTED=0
    FAILED=0

    while IFS= read -r raw; do
        xmp="$(_find_xmp "$raw")"
        rating="$(_xmp_rating "$xmp")"

        if _run_darktable_export "$raw" "$xmp" "$OUT_DIR" "$PRESET"; then
            log_ok "★${rating}  $(basename "$raw")"
            EXPORTED=$((EXPORTED + 1))
        else
            log_error "★${rating}  $(basename "$raw")  (export failed)"
            FAILED=$((FAILED + 1))
        fi
    done < "$tmp_list"

    rm -f "$tmp_list"

    printf '\n'
    if [ "$FAILED" -eq 0 ]; then
        log_ok "Done: $EXPORTED image(s) exported → $OUT_DIR"
    else
        log_ok "Done: $EXPORTED exported, $FAILED failed → $OUT_DIR"
    fi
}

# ── Helpers ───────────────────────────────────────────────────────────────────

# Find the XMP sidecar for a RAW file.
# darktable writes: DSC00001.ARW.xmp  (appends .xmp to the full filename)
# Some tools write: DSC00001.xmp      (replaces extension)
# Returns the sidecar path, or empty string if neither form exists.
_find_xmp() {
    raw="$1"
    dir="$(dirname "$raw")"
    base="$(basename "$raw")"

    # darktable convention: DSC00001.ARW.xmp
    f="${dir}/${base}.xmp"
    [ -f "$f" ] && { printf '%s\n' "$f"; return; }

    # Extension-replaced convention: DSC00001.xmp
    f="${dir}/${base%.*}.xmp"
    [ -f "$f" ] && { printf '%s\n' "$f"; return; }
}

# Read xmp:Rating from an XMP sidecar file.
#
# XMP stores rating in one of two forms depending on the writing application:
#
#   Attribute (darktable, Lightroom):
#     <rdf:Description ... xmp:Rating="5" ...>
#
#   Element (digiKam, Exiftool):
#     <xmp:Rating>5</xmp:Rating>
#
# The sed expression below matches both forms by looking for the literal string
# "xmp:Rating" followed by zero or more non-digit characters, then captures the
# optional minus sign and digit(s) that follow.
#
# Returns the rating integer (-1 to 5), or empty string if not present.
_xmp_rating() {
    xmp="$1"
    [ -f "$xmp" ] || return
    sed -n 's/.*xmp:Rating[^0-9-]*\(-\{0,1\}[0-9]\{1,\}\).*/\1/p' "$xmp" | head -1
}

# Locate darktable-cli.
# Checks PATH first, then the standard macOS app bundle location.
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

# Export a single RAW file using darktable-cli.
# The XMP sidecar is passed explicitly so darktable applies the full edit history.
# Returns 0 on success, non-zero on failure.
_run_darktable_export() {
    raw="$1"
    xmp="$2"
    out_dir="$3"
    preset="$4"

    case "$preset" in
        web)
            "$_DARKTABLE_CLI" "$raw" "$xmp" "$out_dir" \
                --out-ext jpg \
                --icc-type SRGB \
                --width 1920 --height 1920 \
                --hq true \
                >/dev/null 2>&1
            ;;
        print)
            "$_DARKTABLE_CLI" "$raw" "$xmp" "$out_dir" \
                --out-ext jpg \
                --icc-type ADOBERGB \
                --hq true \
                >/dev/null 2>&1
            ;;
    esac
}
