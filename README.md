# photo-os

A personal photography workflow system for Sony A7C II shooters on macOS.

Built for long-term maintainability (5–10 years), full automation, and reproducibility.

---

## Overview

`photo-os` is an opinionated, script-driven photography workflow that covers every stage from import to archive. It is designed for a software engineer who wants to manage RAW files, editing presets, and portfolio curation with the same discipline applied to a software project.

**Stack:**
- Camera: Sony A7C II (`.ARW` RAW files)
- RAW Editor: [darktable](https://www.darktable.org/)
- Photo Manager: [digiKam](https://www.digikam.org/)
- OS: macOS
- Scripts: POSIX shell

---

## Folder Structure

### Repository (`photo-os/`)

```
photo-os/
├── README.md               # This file
├── docs/                   # Workflow documentation
│   ├── workflow.md         # Full workflow overview (Shoot → Archive)
│   ├── folder-convention.md
│   ├── darktable.md        # darktable workflow & settings
│   ├── digikam.md          # digiKam workflow & settings
│   ├── portfolio.md        # Portfolio curation SOP
│   └── scripts.md          # CLI script reference
├── scripts/                # Automation scripts
│   ├── photo               # Main CLI entry point
│   ├── lib/                # Shared library functions
│   └── commands/           # Sub-commands (new, import, export, ...)
├── presets/                # darktable styles & digiKam configs
│   ├── darktable/
│   │   ├── styles/         # .dtstyle export files
│   │   └── presets/        # darktable export presets
│   └── digikam/            # digiKam filter/search templates
├── templates/              # Boilerplate files
│   └── session-notes.md    # Template for per-session shoot notes
└── examples/               # Example outputs & demo configs
```

### Photo Library (`~/Photography/`)

```
Photography/
├── RAW/
│   └── YYYY/
│       └── YYYY-MM-DD Location Theme/   # e.g. 2025-06-15 Tokyo Street
│           ├── *.ARW                    # Sony RAW files
│           └── *.xmp                    # darktable sidecar files
├── Export/
│   └── YYYY-MM-DD Location Theme/      # Exported JPEGs (same name as RAW session)
│       ├── web/                         # Instagram / social (1080px, sRGB)
│       └── print/                       # High-res print (full res, AdobeRGB)
└── Portfolio/
    └── YYYY-MM-DD Location Theme/      # Final portfolio selects (symlinks or copies)
```

**Purpose of each folder:**

| Folder | Purpose |
|--------|---------|
| `RAW/YYYY/YYYY-MM-DD .../` | Permanent RAW archive. Never delete. One folder per shoot session. |
| `Export/YYYY-MM-DD .../web/` | Social-ready exports. Can be regenerated from RAW. |
| `Export/YYYY-MM-DD .../print/` | High-res exports for print or licensing. |
| `Portfolio/` | Curated best work. Slow-moving, high signal. |

---

## Workflow

```
Shoot → Import → Rate → Edit → Export → Curate → Portfolio → Archive
```

**Tool responsibilities:**

| Stage | Tool | Role |
|-------|------|------|
| Import | `photo import` | Copy RAW files; set current session |
| Rate / Cull | digiKam | Star ratings written to `.xmp` sidecars |
| Edit | darktable | Non-destructive edits; writes `.xmp` sidecars |
| Export | darktable | Export JPEGs to the session's `Export/` folder |
| Curate | `photo curate` *(v0.3)* | Promote ★5 JPEGs to `Portfolio/` |
| Archive | `photo backup` | Sync RAW + Export to backup destinations |

darktable is **only** responsible for editing and exporting. It never decides where files go — that is defined by the session structure and retrieved via `photo export-path`.

### 1. Shoot
- Memory card → Sony A7C II records `.ARW` files

### 2. Import
```sh
photo import /Volumes/MEMORY_CARD
```
- Prompts for project name; prepends today's date automatically
- Creates `RAW/`, `Export/web/`, `Export/print/`, `Portfolio/` folders
- Sets this session as **current** (`~/.photo-os/current-session`)

### 3. Rate
- Open session in digiKam
- Use star ratings (written to `.xmp`):
  - ★★★★★ (5) → Portfolio candidate
  - ★★★★☆ (4) → Export candidate
  - ★★★☆☆ (3) → Keep, do not export
  - ✗ Rejected → Discard

### 4. Edit
- Open ★4+ images in darktable darkroom
- Apply styles; all edits saved to `.xmp` sidecar files (non-destructive)
- RAW files are never modified

### 5. Export
```sh
photo export-path   # prints: ~/Photography/Export/2026-07-08 .../web
```
- Copy the printed path into darktable's export destination field
- Export ★4+ images with the `photo-os web` or `photo-os print` preset
- JPEGs land in the session's `Export/web/` or `Export/print/` folder

### 6. Curate
```sh
photo open export     # review exported JPEGs in Finder
```
- Manually promote best images to `Portfolio/` *(automated in v0.3)*
- See [docs/portfolio.md](docs/portfolio.md) for the curation SOP

### 7. Archive
```sh
photo backup
```
- Syncs `RAW/` and `Export/` to configured backup destinations
- RAW + `.xmp` sidecars are the single source of truth

---

## Tools

### Sony A7C II
- Shoots compressed `.ARW` (14-bit RAW)
- EXIF contains full metadata: focal length, ISO, aperture, shutter speed, GPS (if enabled)

### darktable
- Open-source RAW processor (non-destructive, `.xmp` sidecars)
- Used for: culling, color grading, noise reduction, export
- See [docs/darktable.md](docs/darktable.md) for full workflow

### digiKam
- Open-source photo management (reads `.xmp`, supports album/tag/rating)
- Used for: library browsing, tag search, album organization
- See [docs/digikam.md](docs/digikam.md) for full workflow

---

## Quick Start

```sh
# Clone the workflow repo
git clone https://github.com/henry-wu-1130/photo-os ~/photo-os

# Install the photo CLI
ln -sf ~/photo-os/scripts/photo /usr/local/bin/photo

# Import from memory card (prompts for project name, sets current session)
photo import /Volumes/MEMORY_CARD

# Check current session paths
photo current

# Get the export path to paste into darktable
photo export-path

# Open exported JPEGs in Finder
photo open export
```

---

## Roadmap

See [docs/roadmap.md](docs/roadmap.md) for detailed version planning.

| Version | Focus |
|---------|-------|
| v0.1 | Directory conventions, README, docs skeleton |
| v0.2 | `photo new`, `photo import`, `photo backup` scripts |
| v0.3 | darktable styles, `photo export`, digiKam setup |
| v1.0 | Full workflow end-to-end, tested and documented |

---

## Principles

- **Keep It Simple** — prefer convention over configuration
- **Automation First** — every repetitive step should be a script
- **One Source of Truth** — RAW files are canonical; exports are derived
- **Reproducible Workflow** — same script, same result, every time
- **Long-term Maintainability** — no proprietary lock-in, plain files, standard tools
