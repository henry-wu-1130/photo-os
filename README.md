# photo-os

A CLI that orchestrates the photography workflow for Sony A7C II shooters on macOS.

---

## Philosophy

photo-os is not a photo editor. It is not a photo manager.

It is a workflow orchestrator — a thin layer that connects the tools you already use and automates the parts that are repetitive and mechanical.

Each tool in the stack has exactly one responsibility:

| Tool | Responsibility |
|------|---------------|
| **photo-os** | Session management, import, export orchestration |
| **digiKam** | Browse, rate, cull |
| **darktable** | RAW editing, XMP sidecars |
| **darktable-cli** | Batch JPEG export |

No tool reaches into another tool's domain.

---

## Workflow

```
Shoot → Import → Cull → Edit → Export → Portfolio
```

### 1. Shoot

Shoot with the Sony A7C II. RAW files (`.ARW`) are written to the memory card.

### 2. Import

```sh
photo import
```

Auto-detects the SD card. Prompts for a project name. The date is added automatically.

Creates the full session structure and remembers it as the **current session**:

```
RAW/2026/2026-07-08 Taipei Blue Hour/
Export/2026-07-08 Taipei Blue Hour/web/
Export/2026-07-08 Taipei Blue Hour/print/
Portfolio/2026-07-08 Taipei Blue Hour/
```

### 3. Cull

Open the session in **digiKam**. Browse, rate, and cull.

- Reject technically broken shots.
- Rate the rest 1–5 stars.
- ★5 = best of the session.

### 4. Edit

Open the rated images in **darktable**. Edit RAW files. Save edits to `.xmp` sidecars.

RAW files are never modified. All edits live in `.xmp`.

### 5. Export

```sh
photo export web      # → Export/<session>/web/
photo export print    # → Export/<session>/print/
```

photo-os calls `darktable-cli` to batch export every RAW file in the session. If an `.xmp` sidecar exists, darktable-cli applies the full edit history automatically. No GUI interaction required.

### 6. Portfolio

```sh
photo open export     # opens Export/<session>/web/ in Finder
```

Review the exported JPEGs. Manually copy the best images into `Portfolio/`.

Portfolio is intentionally manual. photo-os does not decide what belongs there.

---

## Folder Structure

### Photo Library (`~/Photography/`)

```
Photography/
├── RAW/
│   └── YYYY/
│       └── YYYY-MM-DD Project/         ← one folder per session
│           ├── DSC00001.ARW
│           └── DSC00001.ARW.xmp        ← darktable edit history
├── Export/
│   └── YYYY-MM-DD Project/
│       ├── web/                         ← 1920px, sRGB, JPEG
│       └── print/                       ← full res, AdobeRGB, JPEG
└── Portfolio/
    └── YYYY-MM-DD Project/              ← manually curated final selects
```

| Folder | Role |
|--------|------|
| `RAW/` | Permanent archive. Source of truth. Never delete. |
| `Export/` | Reproducible JPEG artifacts. Generated from RAW + XMP. |
| `Portfolio/` | Curated final work. Manually maintained. |

**RAW + XMP are the source of truth.** Exports can always be regenerated.

### Repository (`~/photo-os/`)

```
photo-os/
├── scripts/
│   ├── photo               ← CLI entry point
│   ├── lib/common.sh       ← shared utilities
│   └── commands/           ← one file per subcommand
├── presets/darktable/      ← .dtstyle files and export preset specs
├── templates/              ← session-notes.md template
└── docs/                   ← workflow documentation
```

---

## CLI Reference

### Session

```sh
photo import                              # auto-detect SD card, import, set session
photo new "2026-07-08 Taipei Blue Hour"   # create session manually
photo current                             # show RAW, Export, Portfolio paths
photo open raw                            # open RAW folder in Finder
photo open export                         # open Export/web/ in Finder
photo open portfolio                      # open Portfolio folder in Finder
photo export-path                         # print web export path (for darktable GUI)
```

### Export

```sh
photo export web       # batch export all RAW → Export/<session>/web/
photo export print     # batch export all RAW → Export/<session>/print/
photo export web --dry-run   # preview without exporting
```

Export is performed by `darktable-cli`. No darktable GUI automation. No rating filter — export everything in the session. Cull in digiKam before exporting.

### Library

```sh
photo backup     # sync RAW and Export to backup destinations
photo status     # library summary
```

---

## Getting Started

**Requirements:** macOS, `rsync`, [darktable](https://www.darktable.org/), [digiKam](https://www.digikam.org/).

```sh
# 1. Clone
git clone https://github.com/henry-wu-1130/photo-os ~/photo-os

# 2. Install the CLI
ln -sf ~/photo-os/scripts/photo /usr/local/bin/photo

# 3. Import from memory card
photo import
# auto-detects SD card → prompts: Project name: Taipei Blue Hour
# creates: RAW/2026/2026-07-08 Taipei Blue Hour/ + Export/ + Portfolio/

# 4. After culling in digiKam and editing in darktable:
photo export web

# 5. Review exports in Finder
photo open export

# 6. Backup
photo backup
```

---

## darktable Integration

darktable owns **editing only**. It writes edits to `.xmp` sidecar files.

`photo export` calls `darktable-cli` — the headless darktable CLI — to batch export without opening the GUI:

| Preset | Color profile | Max size | Output |
|--------|--------------|----------|--------|
| `web` | sRGB | 1920 × 1920 px | `Export/<session>/web/` |
| `print` | AdobeRGB | Full resolution | `Export/<session>/print/` |

darktable-cli automatically picks up the `.xmp` sidecar alongside each `.ARW`. No manual selection required.

See [docs/darktable.md](docs/darktable.md) for editing workflow and style conventions.

---

## digiKam Integration

digiKam owns **browse, rate, and cull**. It reads and writes `xmp:Rating` to `.xmp` sidecar files, shared with darktable.

Recommended workflow after import:
1. Open the session album in digiKam.
2. Reject technically broken shots.
3. Rate the rest 1–5 stars.
4. Edit the rated images in darktable.

Culling in digiKam reduces what gets edited. Everything remaining in the RAW folder gets exported by `photo export`.

See [docs/digikam.md](docs/digikam.md) for setup and keyboard shortcuts.

---

## Principles

- **Keep It Simple** — one tool, one responsibility
- **RAW is the source of truth** — never modify, never delete
- **XMP stores all edit history** — sidecars, not proprietary databases
- **JPEGs are reproducible artifacts** — regenerable from RAW + XMP at any time
- **Current Session is the foundation** — every command derives paths from it
- **Automation removes repetitive work, not creative decisions** — you decide what to keep and what to publish
- **Long-term maintainability** — standard tools, plain files, no vendor lock-in

---

## Roadmap

| Version | Status | Focus |
|---------|--------|-------|
| v0.1 | ✓ Done | Documentation, folder conventions |
| v0.2 | ✓ Done | `photo import`, `photo new`, `photo backup`, `photo status` |
| v0.2.x | ✓ Done | Current session, `photo current`, `photo open`, `photo export-path` |
| v0.3 | ✓ Done | `photo export web/print` via `darktable-cli` |
| v0.4 | Planned | `photo doctor`, `photo stats`, backup improvements |
| v1.0 | Planned | Hardened, fully tested, onboarding in under 30 minutes |

---

## Documentation

- [docs/workflow.md](docs/workflow.md) — stage-by-stage workflow
- [docs/darktable.md](docs/darktable.md) — darktable editing and export
- [docs/digikam.md](docs/digikam.md) — digiKam culling and rating
- [docs/portfolio.md](docs/portfolio.md) — portfolio curation SOP
- [docs/scripts.md](docs/scripts.md) — CLI reference
- [docs/folder-convention.md](docs/folder-convention.md) — naming rules
- [docs/roadmap.md](docs/roadmap.md) — versioned roadmap
