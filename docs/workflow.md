# Workflow Overview

```
Shoot → Import → Rate → Edit → Export → Curate → Portfolio → Archive
```

## Tool Responsibilities

Each tool owns exactly one stage. No tool reaches into another tool's domain.

| Stage | Tool | Output |
|-------|------|--------|
| Shoot | Sony A7C II | `.ARW` files on memory card |
| Import | `photo import` | RAW files in library; current session set |
| Rate | digiKam | Star ratings in `.xmp` sidecar files |
| Edit | darktable | Edit history in `.xmp` sidecar files |
| Export | `photo export web` | JPEGs in `Export/<session>/web/` or `print/` |
| Curate | `photo open export` + manual | Selected JPEGs copied to `Portfolio/` |
| Archive | `photo backup` | Synced copies on backup drives |

**Rating drives export.** `photo export` reads `xmp:Rating` from each sidecar and exports only images rated ★5 (configurable). darktable handles the rendering; photo-os decides what gets rendered and where it goes.

---

## Source of Truth

| Data | Canonical location |
|------|--------------------|
| RAW files | `RAW/YYYY/<session>/*.ARW` |
| Edit history | `RAW/YYYY/<session>/*.xmp` (darktable sidecar) |
| Ratings | `RAW/YYYY/<session>/*.xmp` (shared by darktable + digiKam) |
| Exports | `Export/<session>/web/` and `print/` — **derived, regenerable** |
| Portfolio | `Portfolio/<session>/` — curated copies of web exports |

Export JPEGs and Portfolio copies can always be regenerated from RAW + XMP. They are not the source of truth.

---

## Stage 1: Shoot

**Who does it:** You, in the field.

**Output:** Memory card with `.ARW` files.

Best practices:
- Enable GPS on A7C II if location metadata is desired.
- Note location and theme immediately after shooting.

---

## Stage 2: Import

**Goal:** Move RAW files from memory card → permanent RAW archive.

```sh
photo import /Volumes/MEMORY_CARD
```

**What happens:**
1. Counts `.ARW` files on the source.
2. Checks for existing sessions today; prompts to reuse or enter a new project name.
3. Date is added automatically: `2026-07-08 Taipei Blue Hour`.
4. Creates the full session structure:
   ```
   RAW/2026/2026-07-08 Taipei Blue Hour/
   Export/2026-07-08 Taipei Blue Hour/web/
   Export/2026-07-08 Taipei Blue Hour/print/
   Portfolio/2026-07-08 Taipei Blue Hour/
   ```
5. Copies `.ARW` files with checksum verification; skips duplicates.
6. Saves this session as **current** (`~/.photo-os/current-session`).
7. Ejects memory card (if source is under `/Volumes/`).

---

## Stage 3: Rate

**Goal:** Reduce hundreds of RAW files to ~20 export candidates.

**Tool:** digiKam

**Rating system:**

| Rating | Meaning | `photo export` behaviour |
|--------|---------|--------------------------|
| ★★★★★ | Ready to export | Exported (default) |
| ★★★★ | Candidate — needs review | Exported with `--rating 4` |
| ★★★ | Keep only | Skipped |
| ★★ | Weak | Skipped |
| ✗ | Rejected | Always skipped |

Ratings are written to `xmp:Rating` in the `.xmp` sidecar and are shared between digiKam and darktable. The field is an XMP standard — both tools read and write the same value.

**Target:** ≤20 images rated ★4 or ★5 per session.

See [digikam.md](digikam.md) for setup and keyboard shortcuts.

---

## Stage 4: Edit

**Goal:** Process ★4+ images for final output.

**Tool:** darktable darkroom

- Apply base style (exposure, WB, noise reduction).
- Apply look style (color grade, contrast).
- Crop, local adjustments.
- Promote to ★5 if an image is portfolio-worthy.

All edits are stored in `.xmp` sidecars. RAW files are never touched.

See [darktable.md](darktable.md) for module order and style conventions.

---

## Stage 5: Export

**Goal:** Export selected photos — not all edited photos, only those rated ★5.

**Tool:** `photo export` (calls `darktable-cli`)

```sh
photo export web      # export ★5 images to Export/<session>/web/
photo export print    # export ★5 images to Export/<session>/print/
```

**What happens:**
1. Reads the current session.
2. Scans `RAW/<session>/*.ARW` for sidecar files.
3. Parses `xmp:Rating` from each `.xmp` sidecar.
4. Passes ★5 images to `darktable-cli` one by one.
5. darktable-cli applies the full edit history from the `.xmp` and renders the JPEG.
6. Output lands in `Export/<session>/web/` or `print/`.

**Presets:**

| Command | ICC profile | Max size | Output folder |
|---------|-------------|----------|---------------|
| `photo export web` | sRGB | 1920 × 1920 px | `web/` |
| `photo export print` | AdobeRGB | full resolution | `print/` |

**Flags:**
- `--rating N` — export images rated ★N or above (default: 5)
- `--dry-run` — list which files would be exported without exporting

**Fallback (darktable GUI):**
```sh
photo export-path
# → /Users/you/Photography/Export/2026-07-08 Taipei Blue Hour/web
```
Paste this path into darktable's Export destination field for manual export.

---

## Stage 6: Curate

**Goal:** Select best images for Portfolio.

```sh
photo open export   # opens Export/web/ in Finder
```

Manually copy the 1–3 best images per session into `Portfolio/<session>/`.

See [portfolio.md](portfolio.md) for the full curation SOP (100 → 20 → 5).

---

## Stage 7: Archive

**Goal:** Ensure RAW + XMP + exports are safe on multiple media.

```sh
photo backup
```

Syncs `$PHOTO_ROOT` to `BACKUP_PRIMARY` and `BACKUP_SECONDARY` using rsync with checksum verification.

Strategy: 3-2-1 (3 copies, 2 media types, 1 offsite).

---

## Current Session

After `photo import` or `photo new`, the session is saved to `~/.photo-os/current-session`. All subsequent commands that need a session path read from this file automatically.

```sh
photo current       # show all paths for current session
photo export-path   # print web export path only (paste into darktable)
photo open raw      # open RAW folder in Finder
photo open export   # open Export/web/ in Finder
photo open portfolio # open Portfolio folder in Finder
```

To switch sessions manually:
```sh
photo new "2026-07-09 Taipei Night"   # creates + sets as current
```
