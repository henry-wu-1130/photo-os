# photo-os

A lightweight CLI that orchestrates a personal photography workflow on macOS.

Built for engineers who want their photography process to feel as disciplined as their code.

---

## What It Is

`photo-os` is a shell-based workflow tool for Sony A7C II shooters. It handles the parts of photography that are tedious and mechanical — importing, organizing, navigating folders — so you can focus on shooting and editing.

It is **not** a photo manager. It does not replace:

- **digiKam** — for browsing, rating, and culling
- **darktable** — for RAW editing

`photo-os` connects the dots between them.

---

## Workflow

```
Shoot → Import → Rate → Edit → Export → Curate → Portfolio
```

| Stage | Tool | What happens |
|-------|------|-------------|
| Shoot | Sony A7C II | RAW files recorded to memory card |
| Import | `photo import` | Files copied to library; session created and remembered |
| Rate & Cull | digiKam | Star ratings written to `.xmp` sidecars |
| Edit | darktable | Edits written to `.xmp` sidecars; RAW untouched |
| Export | `photo export web` | ★5 photos exported via darktable-cli |
| Curate | `photo open export` + manual | Best JPEGs promoted to `Portfolio/` |
| Portfolio | *(automated in v0.3)* | Curated final works |

---

## Folder Structure

### Library (`~/Photography/`)

```
Photography/
├── RAW/
│   └── YYYY/
│       └── YYYY-MM-DD Project/     ← one folder per session
│           ├── DSC00001.ARW
│           └── DSC00001.xmp        ← darktable sidecar
├── Export/
│   └── YYYY-MM-DD Project/
│       ├── web/                    ← 1080px, sRGB, JPEG 90%
│       └── print/                  ← full res, AdobeRGB, JPEG 95%
└── Portfolio/
    └── YYYY-MM-DD Project/         ← curated final selects
```

| Folder | Role |
|--------|------|
| `RAW/` | Permanent archive. Never delete. Source of truth. |
| `Export/` | Derived outputs. Regenerable from RAW + XMP. |
| `Portfolio/` | Curated best work. Intentionally small. |

### Repository (`~/photo-os/`)

```
photo-os/
├── scripts/
│   ├── photo               ← CLI entry point
│   ├── lib/common.sh       ← shared utilities
│   └── commands/           ← one file per subcommand
├── presets/darktable/      ← .dtstyle files and export preset specs
├── templates/              ← session-notes.md template
└── docs/                   ← detailed workflow documentation
```

---

## CLI

### Current Session

After `photo import`, photo-os remembers the active session. Every subsequent command reads it automatically — no path typing required.

```sh
photo current          # show RAW, Export, and Portfolio paths
photo open raw         # open RAW folder in Finder
photo open export      # open Export/web/ in Finder
photo open portfolio   # open Portfolio folder in Finder
photo export-path      # print web export path (paste into darktable)
```

### Session Management

```sh
photo new "2026-07-08 Taipei Blue Hour"   # create session + set as current
photo import /Volumes/MEMORY_CARD         # import RAW files + set as current
```

`photo import` prompts for a project name only. The date is added automatically.

### Library

```sh
photo backup    # sync RAW and Export to backup destinations
photo status    # library summary: sessions, file counts, last backup
```

### Future (v0.3)

```sh
photo export      # batch export via darktable-cli (no GUI required)
photo curate      # promote ★5 JPEGs to Portfolio/
photo doctor      # check dependencies and config health
```

---

## Getting Started

**Requirements:** macOS, `rsync` (pre-installed), darktable, digiKam.

```sh
# 1. Clone
git clone https://github.com/henry-wu-1130/photo-os ~/photo-os

# 2. Install the CLI
ln -sf ~/photo-os/scripts/photo /usr/local/bin/photo

# 3. Import your first session
photo import /Volumes/MEMORY_CARD
# → prompts: Project name: Taipei Blue Hour
# → creates: 2026-07-08 Taipei Blue Hour

# 4. Check the session
photo current

# 5. Rate images in digiKam (★5 = ready to export), then:
photo export web
# → exports ★5 images via darktable-cli
# → output: ~/Photography/Export/2026-07-08 Taipei Blue Hour/web/

# 6. Review exports
photo open export

# 7. Backup
photo backup
```

---

## darktable Integration

darktable is responsible for one thing: **editing RAW files**.

Edits are saved to `.xmp` sidecar files. darktable never decides what gets exported or where — that is photo-os's responsibility.

```sh
photo export web
# Reads xmp:Rating from each .xmp → exports ★5 images via darktable-cli
# Output: ~/Photography/Export/2026-07-08 Taipei Blue Hour/web/
```

`photo export` uses `darktable-cli` — no GUI required. darktable applies the full edit history from the `.xmp` sidecar when rendering each JPEG.

See [docs/darktable.md](docs/darktable.md) for editing workflow and setup.

---

## digiKam Integration

digiKam is used after import, before editing: **browse, rate, cull**.

The minimum effective setup:
1. Point digiKam at `~/Photography` as a collection.
2. Enable XMP sidecar sync (so ratings are shared with darktable).
3. Rate images ★1–5 using keyboard shortcuts.

Ratings written in digiKam are immediately visible in darktable, and vice versa — they share the same `.xmp` files.

See [docs/digikam.md](docs/digikam.md) for setup and rating conventions.

---

## Principles

- **RAW is the source of truth.** Exports and Portfolio copies are derived and regenerable.
- **One session, one project.** A shoot session maps to exactly one folder set.
- **Edit first, export second.** Never export before editing is complete.
- **Exports are reproducible.** Given the same RAW + XMP, the same JPEG can always be regenerated.
- **Portfolio is intentionally small.** Quality over quantity. Prune regularly.
- **Automation reduces friction, not awareness.** You still make every creative decision.
- **Keep the CLI simple.** If a command needs a man page, it's too complex.

---

## Roadmap

| Version | Status | Focus |
|---------|--------|-------|
| v0.1 | ✓ Done | Directory conventions, documentation skeleton |
| v0.2 | ✓ Done | Core CLI: `new`, `import`, `backup`, `status`, `current`, `open`, `export-path` |
| v0.3 | Planned | `photo export` via `darktable-cli`, `photo curate`, darktable styles |
| v1.0 | Planned | Hardened, tested, `photo doctor`, onboarding in under 30 min |

See [docs/roadmap.md](docs/roadmap.md) for details.

---

## Documentation

- [docs/workflow.md](docs/workflow.md) — full stage-by-stage breakdown
- [docs/darktable.md](docs/darktable.md) — darktable setup, editing, and export
- [docs/digikam.md](docs/digikam.md) — digiKam setup, rating, and culling
- [docs/portfolio.md](docs/portfolio.md) — portfolio curation SOP
- [docs/scripts.md](docs/scripts.md) — CLI reference
- [docs/folder-convention.md](docs/folder-convention.md) — naming rules
