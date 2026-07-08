# Folder Convention

## Photo Library Root

Default: `~/Photography/`

Override by setting `PHOTO_ROOT` in `~/.photo-os/config`.

---

## Directory Tree

```
Photography/
├── RAW/
│   └── YYYY/
│       └── YYYY-MM-DD Location Theme/
│           ├── DSC00001.ARW
│           ├── DSC00001.xmp    ← darktable sidecar
│           └── ...
├── Export/
│   └── YYYY-MM-DD Location Theme/
│       ├── web/
│       │   └── DSC00001_web.jpg
│       └── print/
│           └── DSC00001_print.jpg
└── Portfolio/
    └── YYYY-MM-DD Location Theme/
        └── DSC00001_web.jpg    ← copied from Export/
```

---

## Session Name Format

```
YYYY-MM-DD Location Theme
```

**Rules:**
- Date: ISO 8601, always 10 characters (`2025-06-15`)
- Location: city, area, or landmark (no commas)
- Theme: shoot type or subject (optional but recommended)
- Separator: single space between each component
- No special characters except hyphens and spaces

**Examples:**
```
2025-06-15 Tokyo Street
2025-07-04 Kyoto Temple Architecture
2025-08-20 Taipei Portrait
2025-12-31 Home Still Life
```

**Why this format:**
- Sorts chronologically in any file manager
- Human-readable without parsing
- Compatible with `find`, `ls`, `rsync` without escaping issues (when quoted)

---

## RAW/

**Purpose:** Permanent archive. Never delete files from here.

- One subfolder per calendar year for manageable size.
- One subfolder per shoot session.
- `.xmp` sidecar files live alongside `.ARW` files.
- darktable database also references these paths — do not move without re-importing.

**Size estimate:** ~50MB per RAW file. A 200-shot session ≈ 10GB.

---

## Export/

**Purpose:** Derived outputs. Can always be regenerated from RAW + `.xmp`.

- `web/` — social media ready (1080px, sRGB, JPEG 90%)
- `print/` — high-res for print or client delivery (full res, AdobeRGB, JPEG 95%)
- These folders are created by `photo export`.

---

## Portfolio/

**Purpose:** Slow-moving, high-signal collection of best work.

- Only ★5 images that survive the portfolio review process.
- Files are copied (not symlinked) for portability.
- See [portfolio.md](portfolio.md) for curation SOP.

---

## Config File

`~/.photo-os/config` (created on first run):

```sh
PHOTO_ROOT="$HOME/Photography"
BACKUP_PRIMARY="/Volumes/BackupDrive/Photography"
BACKUP_SECONDARY=""   # e.g. rsync target or rclone remote
```
