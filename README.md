# photo-os

A lightweight CLI that orchestrates a modern photography workflow using digiKam and darktable.

photo-os is not a photo editor. It is not a photo manager.

It connects open-source tools into a single, repeatable workflow — handling the mechanical parts (import, folder structure, batch export) so you can focus on shooting and editing.

---

## Features

- Auto-detect camera SD cards and import RAW files
- Automatic session creation with date-stamped folder structure
- Current Session — every command knows where you are in the workflow
- Batch export via `darktable-cli` — no GUI interaction required
- Open session folders in Finder with a single command
- Reproducible workflow: the same RAW + XMP always produces the same JPEG
- macOS-first, POSIX shell, no external dependencies beyond rsync

---

## Requirements

photo-os works together with two external tools. Install both before getting started.

### digiKam

[digiKam](https://www.digikam.org/) is used for browsing, rating, and culling RAW files.

**Install:** Download from [digikam.org](https://www.digikam.org/)

**Setup:**

1. Open digiKam → **Settings → Configure digiKam → Collections**
2. Add a collection pointing to `~/Photography/RAW`

Keep digiKam focused on RAW files only. Do not add `Export/` or `Portfolio/` as collections.

**Responsibilities in this workflow:**

- Browse the session after import
- Rate images (1–5 stars)
- Cull — reject technically broken shots before editing

### darktable

[darktable](https://www.darktable.org/) is used for RAW editing. All edits are saved to `.xmp` sidecar files. RAW files are never modified.

**Install:** Download from [darktable.org](https://www.darktable.org/)

**darktable-cli:** On macOS, `darktable-cli` is bundled with darktable but not added to `PATH` automatically. photo-os looks for it here:

```
/Applications/darktable.app/Contents/MacOS/darktable-cli
```

If you have a custom install, add `darktable-cli` to your `PATH` and photo-os will find it.

**Responsibilities in this workflow:**

- Edit RAW files in the darkroom
- Save edits as `.xmp` sidecar files
- Do **not** export from the darktable GUI — use `photo export` instead

---

## Workflow

```
Shoot
  ↓
photo import
  ↓
digiKam
  Browse · Rate · Cull
  ↓
darktable
  Edit RAW · Save XMP
  ↓
photo export web
  or
photo export print
  ↓
Export/<session>/web/
  ↓
Manual review
  ↓
Portfolio/
  ↓
Instagram · Print
```

**Shoot** — Capture RAW files on the Sony A7C II. Files are stored as `.ARW` on the memory card.

**Import** — Insert the SD card and run `photo import`. photo-os auto-detects the card, prompts for a project name, creates the session folders, copies the RAW files, and remembers the session as the Current Session.

**Cull** — Open the session in digiKam. Reject technically broken shots. Rate the rest 1–5 stars.

**Edit** — Open the rated images in darktable. Edit normally. Save edits to `.xmp` sidecars. Do not export from darktable's GUI.

**Export** — Run `photo export web` or `photo export print`. photo-os calls `darktable-cli` to batch export every RAW file in the session. Edits from `.xmp` sidecars are applied automatically.

**Portfolio** — Open the export folder in Finder (`photo open export`), review the JPEGs, and manually move the best images into `Portfolio/`. This step is intentionally manual — photo-os does not decide what belongs in your portfolio.

---

## Installation

```sh
# 1. Clone the repository
git clone https://github.com/henry-wu-1130/photo-os.git ~/photo-os

# 2. Create a symlink to make the CLI available system-wide
ln -sf ~/photo-os/scripts/photo /usr/local/bin/photo

# 3. Verify
photo help
```

`/usr/local/bin` must be in your `PATH`. On a standard macOS installation, it is.

---

## Quick Start

### Import a shoot

Insert the camera SD card, then:

```sh
photo import
```

photo-os will:

1. Scan `/Volumes` for a directory containing `DCIM/` — the standard camera card indicator
2. Prompt for a project name (date is added automatically)
3. Create the session folder structure
4. Copy all `.ARW` files with checksum verification
5. Copy `session-notes.md` template into the RAW folder
6. Remember this as the **Current Session**
7. Eject the SD card

Example output:

```
✓ Camera card detected
  Source: /Volumes/Untitled

Project name: Taipei Blue Hour

✓ RAW:       ~/Photography/RAW/2026/2026-07-08 Taipei Blue Hour
✓ Export:    ~/Photography/Export/2026-07-08 Taipei Blue Hour (web/ print/)
✓ Portfolio: ~/Photography/Portfolio/2026-07-08 Taipei Blue Hour
✓ Current:   2026-07-08 Taipei Blue Hour

Copying 24 .ARW file(s)...
✓ Import complete: 24 / 24 file(s)
```

### Check the current session

```sh
photo current
```

```
Session:   2026-07-08 Taipei Blue Hour

RAW:       ~/Photography/RAW/2026/2026-07-08 Taipei Blue Hour
Export:    ~/Photography/Export/2026-07-08 Taipei Blue Hour
Portfolio: ~/Photography/Portfolio/2026-07-08 Taipei Blue Hour
```

### Review and cull in digiKam

Open the RAW folder:

```sh
photo open raw
```

Browse, rate, and reject in digiKam. Ratings are written to `.xmp` sidecar files.

### Edit in darktable

Open images in darktable. Edit normally. Save — edits go to `.xmp`. Do not use darktable's Export dialog.

### Batch export

```sh
photo export web
```

```
Current Session

  2026-07-08 Taipei Blue Hour

Found

  24 RAW file(s)

Export target

  ~/Photography/Export/2026-07-08 Taipei Blue Hour/web

Exporting...

████████████████████  24 / 24

Done.

  24 image(s) → .../web
```

For print-resolution JPEGs:

```sh
photo export print
```

Preview without exporting:

```sh
photo export web --dry-run
```

### Review and curate

```sh
photo open export     # opens Export/<session>/web/ in Finder
```

Manually copy the best images into `Portfolio/<session>/`.

---

## Folder Structure

```
~/Photography/
├── RAW/
│   └── YYYY/
│       └── YYYY-MM-DD Project/
│           ├── DSC00001.ARW
│           └── DSC00001.ARW.xmp
├── Export/
│   └── YYYY-MM-DD Project/
│       ├── web/
│       └── print/
└── Portfolio/
    └── YYYY-MM-DD Project/
```

| Folder | Purpose |
|--------|---------|
| `RAW/` | Permanent archive. Source of truth. Never delete. |
| `Export/` | Generated JPEGs. Can be regenerated from RAW + XMP at any time. |
| `Portfolio/` | Manually curated final work. |

Session folders are named `YYYY-MM-DD Project` — sortable by date, readable without parsing.

---

## CLI Reference

### Session management

| Command | Description |
|---------|-------------|
| `photo import` | Auto-detect SD card, import RAW files, set Current Session |
| `photo new "YYYY-MM-DD Project"` | Create a session manually and set it as current |
| `photo current` | Show RAW, Export, and Portfolio paths for the current session |
| `photo open raw` | Open the RAW folder in Finder |
| `photo open export` | Open `Export/<session>/web/` in Finder |
| `photo open portfolio` | Open the Portfolio folder in Finder |
| `photo export-path` | Print the web export path (for pasting into darktable) |

### Export

| Command | Description |
|---------|-------------|
| `photo export web` | Batch export all RAW → `Export/<session>/web/` |
| `photo export print` | Batch export all RAW → `Export/<session>/print/` |
| `photo export web --dry-run` | Preview which files would be exported |

Export settings:

| Preset | Color profile | Max size |
|--------|--------------|----------|
| `web` | sRGB | 1920 × 1920 px |
| `print` | AdobeRGB | Full resolution |

### Library

| Command | Description |
|---------|-------------|
| `photo backup` | Sync RAW and Export to backup destinations |
| `photo status` | Show library summary (sessions, file counts, last backup) |

---

## Philosophy

> One tool, one responsibility.

| Tool | Responsibility |
|------|---------------|
| photo-os | Workflow orchestration |
| digiKam | Photo management |
| darktable | RAW editing |
| darktable-cli | Batch export |

**Automation should remove repetitive work, not creative decisions.**

photo-os handles the mechanical steps — copying files, creating folders, running export commands. You make every creative decision: what to shoot, what to keep, what to publish.

---

## Roadmap

### Current

- `photo import` — SD card auto-detection, session creation, RAW import
- `photo new` — manual session creation
- `photo current` — current session paths
- `photo open` — open session folders in Finder
- `photo export web/print` — batch export via `darktable-cli`
- `photo backup` — rsync to backup destinations
- `photo status` — library summary

### Future

- `photo doctor` — check dependencies and configuration health
- `photo stats` — shooting statistics (sessions, file counts, gear usage)
- `photo backup` improvements — cloud sync, verification reports
- Native GUI built on top of the CLI
- Drag-and-drop workflow

---

## Documentation

- [docs/workflow.md](docs/workflow.md) — stage-by-stage workflow
- [docs/darktable.md](docs/darktable.md) — darktable editing and export
- [docs/digikam.md](docs/digikam.md) — digiKam setup, rating, and culling
- [docs/portfolio.md](docs/portfolio.md) — portfolio curation SOP
- [docs/scripts.md](docs/scripts.md) — CLI reference
- [docs/roadmap.md](docs/roadmap.md) — detailed version history
