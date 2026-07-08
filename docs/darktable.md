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

darktable's role in export is **applying edits and rendering the JPEG**. Deciding *which* images to export and *where* they go is photo-os's responsibility.

### Automated export (recommended)

```sh
photo export web
```

This calls `darktable-cli` for every image in the current session that is rated ★5 in digiKam. The JPEG is written to `Export/<session>/web/`. No darktable GUI required.

```sh
photo export print          # full-res, AdobeRGB
photo export web --rating 4 # include ★4 candidates too
photo export web --dry-run  # preview without exporting
```

See [docs/scripts.md](scripts.md) for the full `photo export` reference.

### Manual export (fallback)

If you need to export from the darktable GUI:

```sh
photo export-path
# → /Users/you/Photography/Export/2026-07-08 Taipei Blue Hour/web
```

Paste that path into darktable's **Export** destination field. This is useful for one-off exports or when you want to use darktable's export presets directly.

### darktable-cli

`photo export` uses `darktable-cli` with the following parameters:

| Preset | `--icc-type` | `--width / --height` | Format |
|--------|-------------|----------------------|--------|
| `web` | `SRGB` | 1920 × 1920 (long edge) | JPEG |
| `print` | `ADOBERGB` | full resolution | JPEG |

The XMP sidecar is passed explicitly so darktable applies the full edit history from the sidecar, not just the default processing pipeline.
