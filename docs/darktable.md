# darktable

darktable is the RAW editor in this workflow. Its role is narrowly defined:

- **Edit** RAW files non-destructively
- **Write** edits to `.xmp` sidecar files
- **Export** JPEGs to the location specified by `photo export-path`

darktable does **not** decide folder structure or session organization. photo-os handles that.

> GUI automation is intentionally out of scope. A future `photo export` command will use `darktable-cli` for headless batch export.

Version target: darktable 4.x

---

## Initial Setup

### Preferences

**Storage — most important:**
- `Preferences → Storage → XMP → Write sidecar files for each image: on`

This is the most critical setting. Without it, edits exist only in darktable's database and are lost if the database is corrupted or the library is moved.

**Lighttable:**
- `Preferences → Lighttable → Thumbnails → Use on-disk thumbnail cache` — faster browsing for large sessions

**Import behavior:**
- `Preferences → Import → Only import new images` — avoids re-importing duplicates

---

## Opening a Session

1. In darktable lighttable, press `Ctrl+I` (Import).
2. Choose **Import folder**.
3. Navigate to the session folder: `~/Photography/RAW/YYYY/YYYY-MM-DD Project/`.
4. Import. darktable creates `.xmp` sidecars for each image.

**Do not move files after import.** darktable stores absolute paths. If you need to restructure, use `photo import` first to establish the correct path, then import into darktable.

---

## XMP Sidecar Files

Every edit, rating, and color label is stored in a `.xmp` sidecar file alongside the `.ARW`:

```
RAW/2026/2026-07-08 Taipei Blue Hour/
├── DSC00001.ARW
├── DSC00001.xmp    ← edit history, rating, color labels
├── DSC00002.ARW
└── DSC00002.xmp
```

`.xmp` files are plain XML. They are:
- Human-readable
- Version-controllable
- Readable by both darktable and digiKam

**Back up `.xmp` files with your RAW files** — they are your entire edit history.

To force-write XMP for a session: select all (`Ctrl+A`) → right-click → **Write sidecar files**.

---

## Editing Workflow

Work on ★4+ images (rated in digiKam before this stage).

Recommended module order in the darkroom:

1. **Exposure** — correct exposure offset
2. **White Balance** — set color temperature
3. **Filmic RGB** — compress dynamic range and set tone mapping
4. **Color Calibration** — color correction if needed
5. **Denoise (profiled)** — noise reduction (especially above ISO 1600)
6. **Local adjustments** — masks, dodge/burn
7. **Crop** — final composition

Apply a named style first (base exposure + tone), then make per-image corrections on top.

---

## Styles

Styles are saved groups of module settings — the equivalent of a Lightroom preset.

**Naming convention:**
```
photo-os-base-v1          ← baseline for all images
photo-os-look-warm-v1     ← warm color grade
photo-os-look-film-v1     ← filmic monochrome
```

Apply: right-click image in lighttable → **Styles** → select

Export to file: `Preferences → Styles → [select] → Export` → save to `presets/darktable/styles/`

Style files (`.dtstyle`) in this repository can be imported on a new machine to recreate the exact look.

---

## Export

Export is performed manually via the darktable GUI. photo-os provides the destination path.

### Step-by-step

```sh
# 1. Get the destination path
photo export-path
# → /Users/you/Photography/Export/2026-07-08 Taipei Blue Hour/web
```

2. In darktable lighttable, select all ★4+ images.
3. Open the **Export** panel (bottom right).
4. Set **Destination folder** to the path from step 1.
5. Select a preset and click **Export**.

### Export Presets

Configure these once in darktable and save them by name:

| Preset name | Format | Size | Color profile | Quality |
|-------------|--------|------|---------------|---------|
| `photo-os web` | JPEG | 1080px long edge | sRGB | 90% |
| `photo-os print` | JPEG | Full resolution | AdobeRGB | 95% |
| `photo-os instagram` | JPEG | 1080 × 1350 px | sRGB | 90% |

Preset specifications are documented in [presets/darktable/presets/README.md](../presets/darktable/presets/README.md).

### Instagram Export

- Apply the `photo-os-look-*` style of your choice.
- Use the `photo-os instagram` export preset.
- Output lands in `Export/<session>/web/` with suffix `_ig.jpg`.

---

## darktable-cli (Future)

darktable ships a headless CLI for batch export:

```sh
darktable-cli INPUT.ARW [INPUT.xmp] OUTPUT.jpg [OPTIONS]
```

A future `photo export` command will use this to export all ★4+ images from the current session without opening the GUI. See [docs/roadmap.md](roadmap.md) for v0.3 plans.
