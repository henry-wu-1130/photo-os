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
| Export | darktable (manual) | JPEGs in `Export/<session>/web/` or `print/` |
| Curate | `photo open export` + manual | Selected JPEGs copied to `Portfolio/` |
| Archive | `photo backup` | Synced copies on backup drives |

**darktable is the editor, not the file manager.** It never decides where exports go. The destination is always `photo export-path`, which the user pastes into darktable's export dialog.

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

| Rating | Meaning |
|--------|---------|
| ★★★★★ | Portfolio candidate |
| ★★★★ | Export-worthy |
| ★★★ | Keep, not export |
| ★★ | Weak |
| ✗ | Rejected |

Ratings are written to `.xmp` sidecar files and are readable by both digiKam and darktable.

**Target:** ≤20 images rated ★4+ per session.

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

**Goal:** Generate JPEG derivatives from edited RAW files.

**Tool:** darktable (GUI or CLI in v0.3)

**Step 1** — Get the export destination:
```sh
photo export-path
# → /Users/henry/Photography/Export/2026-07-08 Taipei Blue Hour/web
```

**Step 2** — In darktable:
1. Select ★4+ images in lighttable.
2. Open Export panel.
3. Set destination to the path printed above.
4. Choose preset: `photo-os web` (1080px, sRGB, JPEG 90%).
5. Export.

**Presets:**

| Preset | Size | Profile | Quality | Folder |
|--------|------|---------|---------|--------|
| `photo-os web` | 1080px long edge | sRGB | 90% | `web/` |
| `photo-os print` | Full resolution | AdobeRGB | 95% | `print/` |
| `photo-os instagram` | 1080×1350 | sRGB | 90% | `web/` |

> v0.3 will add `photo export` to automate this via `darktable-cli`.

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
