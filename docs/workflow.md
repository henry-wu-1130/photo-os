# Workflow Overview

```
Shoot → Import → Cull → Edit → Export → Publish → Archive
```

This document describes the end-to-end photography workflow managed by `photo-os`.

---

## Stage 1: Shoot

**Who does it:** You, in the field.

**Output:** Memory card with `.ARW` files.

**Best practices:**
- Enable GPS on A7C II if location metadata is desired.
- Use a consistent file naming scheme on-camera (`DSC_XXXX` is fine; renaming happens on import).
- Write session notes immediately after shooting using `templates/session-notes.md`.

---

## Stage 2: Import

**Goal:** Move RAW files from memory card → permanent RAW archive, with integrity verification.

**Command:** `photo import /Volumes/MEMORY_CARD`

**Steps:**
1. Determine session name (date + location + theme).
2. Create `RAW/YYYY/YYYY-MM-DD Location Theme/`.
3. Copy `.ARW` files using `rsync` with checksum verification.
4. Log file count and total size.
5. Eject memory card safely.

**Do NOT:**
- Delete files from card until backup is confirmed.
- Rename files on import (keep original Sony naming for traceability).

---

## Stage 3: Cull

**Goal:** Reduce hundreds of RAW files to the ~20 best candidates.

**Tool:** darktable lighttable view.

**Rating system:**

| Rating | Stars | Meaning |
|--------|-------|---------|
| Reject | ✗ | Technically unusable (blur, exposure error) |
| 1 | ★ | Keep for reference only |
| 2 | ★★ | Mediocre, not worth editing |
| 3 | ★★★ | Good, keep but not for export |
| 4 | ★★★★ | Export candidate |
| 5 | ★★★★★ | Portfolio candidate |

**Process:**
1. Import session into darktable.
2. First pass: reject technically broken shots (fast, use keyboard shortcuts).
3. Second pass: rate survivors 1–3.
4. Third pass: promote best images to 4–5.
5. Target: ≤20 images rated 4+.

See [darktable.md](darktable.md) for keyboard shortcuts.

---

## Stage 4: Edit

**Goal:** Process ★4+ images for final output.

**Tool:** darktable darkroom view.

**Process:**
1. Apply base style (exposure, white balance, noise reduction).
2. Apply look style (color grading, contrast).
3. Crop and straighten.
4. Local adjustments if needed (dodge/burn, masking).
5. Rate ★5 if it survives editing as a strong image.

All edits are stored in `.xmp` sidecar files. RAW files are never modified.

---

## Stage 5: Export

**Goal:** Generate JPEG derivatives from edited RAW files.

**Command:** `photo export YYYY-MM-DD-Location-Theme`

**Output presets:**

| Preset | Size | Color Profile | Quality | Destination |
|--------|------|--------------|---------|-------------|
| `web` | 1080px long edge | sRGB | JPEG 90% | `Export/.../web/` |
| `print` | Full resolution | AdobeRGB | JPEG 95% | `Export/.../print/` |

Exports are generated for all images rated ★4+.

---

## Stage 6: Publish

**Goal:** Share selected images to social platforms.

**Current flow (manual):**
1. Run `photo review` to open the web export folder.
2. Select images for Instagram/portfolio.
3. Upload manually.

**Future:** `photo publish` will automate platform-specific sizing and metadata.

---

## Stage 7: Archive

**Goal:** Ensure RAW files and exports are safe on multiple storage locations.

**Command:** `photo backup`

**Backup destinations (configure in `~/.photo-os/config`):**
- Local external drive (primary backup)
- Network storage or cloud (secondary backup)

**Strategy:**
- RAW files: 3-2-1 backup (3 copies, 2 media, 1 offsite)
- Exports: at minimum 1 backup copy
- `.xmp` sidecar files: backed up with RAW (same folder)

---

## Keyboard Reference (darktable)

| Key | Action |
|-----|--------|
| `0–5` | Set star rating |
| `r` | Toggle reject |
| `F1–F5` | Color label |
| `Space` | Next image |
| `Backspace` | Previous image |
| `D` | Enter darkroom |
| `L` | Return to lighttable |
