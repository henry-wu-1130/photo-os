# darktable Workflow

darktable is used as the primary RAW processor. All edits are non-destructive and stored in `.xmp` sidecar files.

Version target: darktable 4.x

---

## Initial Setup

### Preferences to configure

**Lighttable:**
- `Settings → Lighttable → Filmstrip → Show overlays: always`
- `Settings → Lighttable → Thumbnails: On-disk cache` (faster for large libraries)

**Storage:**
- Enable `Settings → Storage → XMP → Write sidecar files automatically`
- This ensures edits survive even if the database is lost.

**Import:**
- `Settings → Import → Only import new images` (skip duplicates)

---

## RAW Import

1. In darktable lighttable, click **Import** (or press `Ctrl+I`).
2. Navigate to the session folder under `RAW/YYYY/YYYY-MM-DD .../`.
3. Import **folder** (not individual files).
4. darktable will create `.xmp` sidecar files for each image.

**Do not move files after import** — darktable stores absolute paths. Use `photo import` script to set the correct path before importing into darktable.

---

## Culling (Rating)

In lighttable, use keyboard shortcuts for fast culling:

| Key | Action |
|-----|--------|
| `0` | No rating |
| `1–5` | Star rating |
| `r` | Toggle reject flag |
| `Space` | Next image |
| `Backspace` | Previous image |
| `F1` | Red label (pick) |
| `F2` | Yellow label |
| `F3` | Green label |

**Recommended culling flow:**
1. First pass at full filmstrip speed — reject (`r`) anything clearly broken.
2. Filter to non-rejected. Second pass — rate 1–3.
3. Filter to ★3+. Third pass — promote best to ★4 or ★5.
4. Target: ≤20 images rated ★4+.

---

## XMP Sidecar Files

darktable writes edit history to `.xmp` files automatically (if configured above).

- `.xmp` files are plain XML — version-controllable and human-readable.
- Ratings and color labels are also stored in `.xmp`.
- **Back up `.xmp` files with your RAW files** — they are your edit history.

To force-write XMP for all images in a session:
- Select all (`Ctrl+A`) → right-click → **Write sidecar files**

---

## Styles

Styles are named, reusable groups of darktable module settings.

**Naming convention:**
```
photo-os/base-v1        ← baseline exposure, WB, noise
photo-os/look-warm-v1   ← warm color grade
photo-os/look-film-v1   ← filmic B&W
photo-os/instagram-v1   ← Instagram crop + look
```

**To apply a style:**
- In lighttable: right-click image → Styles → select style
- In darkroom: bottom panel → Styles → select style

**To export styles:**
- `Settings → Styles → Export` → save `.dtstyle` to `presets/darktable/styles/`

---

## Editing Workflow (Darkroom)

Recommended module order (darktable processes bottom-up in pipeline, but work top-down in interface):

1. **Exposure** — set correct exposure
2. **White Balance** — set color temperature
3. **Filmic RGB** — set dynamic range compression and tone mapping
4. **Color Calibration** — correct color if needed
5. **Denoise (profiled)** — noise reduction (especially ISO 1600+)
6. **Local Adjustments** — masks, dodge/burn
7. **Crop** — final composition

Apply base style first, then make per-image adjustments.

---

## Export

### From darktable GUI

1. Select images (★4+) in lighttable.
2. Click **Export** (bottom right).
3. Choose preset:
   - `photo-os web` → JPEG 90%, 1080px long edge, sRGB
   - `photo-os print` → JPEG 95%, full resolution, AdobeRGB
4. Set output path to `Export/YYYY-MM-DD .../web/` or `.../print/`.
5. Click **Export**.

### Via `photo export` script (v0.3+)

```sh
photo export "2025-06-15 Tokyo Street"
```

This calls darktable CLI (`darktable-cli`) to automate the export without opening the GUI.

---

## Instagram Export

Instagram-specific requirements:
- Aspect ratio: 1:1, 4:5, or 1.91:1
- Size: 1080px wide (1080×1080, 1080×1350, or 1080×566)
- Color: sRGB
- Format: JPEG

**darktable style for Instagram:**
1. Apply `photo-os/instagram-v1` style.
2. This style sets:
   - Crop to 4:5 (portrait, recommended for Instagram)
   - Export size: 1080×1350
   - Color profile: sRGB

**Export preset:** `photo-os instagram`
- Output path: `Export/YYYY-MM-DD .../web/`
- Filename suffix: `_ig`

---

## darktable CLI Reference

darktable includes `darktable-cli` for headless export:

```sh
darktable-cli INPUT_FILE [XMP_FILE] OUTPUT_FILE [OPTIONS]

# Export a single file with a specific style
darktable-cli DSC00001.ARW DSC00001.xmp output.jpg \
  --style "photo-os web" \
  --out-ext jpg \
  --icc-type SRGB \
  --width 1080 --height 1080
```

Used internally by `photo export` script.
