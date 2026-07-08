# digiKam Workflow

digiKam is used as the photo library browser and metadata manager. It complements darktable — darktable edits, digiKam organizes.

Keep the digiKam setup simple. The goal is fast search and browsing, not a complex tagging taxonomy.

---

## Philosophy

- **Albums = Sessions** — one album per shoot session, matching the folder structure.
- **Ratings = darktable ratings** — digiKam reads `.xmp` ratings directly.
- **Tags = minimal** — only tag what you can't find via date or album name.
- **Search = primary interface** — use digiKam's search instead of manual browsing.

---

## Initial Setup

### Connect to Photo Library

1. `Settings → Configure digiKam → Collections`
2. Add `~/Photography` as a monitored root collection.
3. digiKam will scan and index all images automatically.

### XMP Sync

digiKam reads and writes `.xmp` sidecar files, compatible with darktable.

- `Settings → Metadata → Behavior → Read metadata from sidecar files: always`
- `Settings → Metadata → Behavior → Write metadata to sidecar files: always`

This ensures ratings set in darktable appear in digiKam and vice versa.

### Face Detection (optional)

Useful for portrait work. Enable under `Settings → Configure digiKam → Face Management`.

---

## Album Structure

Albums in digiKam mirror the filesystem:

```
Photography/
└── RAW/
    └── 2025/
        └── 2025-06-15 Tokyo Street/     ← Album
```

**Do not create manual albums** beyond what the filesystem already provides. The folder naming convention (`YYYY-MM-DD Location Theme`) makes albums self-describing.

---

## Rating System

Ratings are shared with darktable via `.xmp`. Do not maintain separate ratings in digiKam — always set ratings in darktable.

| Rating | Use |
|--------|-----|
| ★★★★★ | Portfolio candidate |
| ★★★★ | Export-worthy |
| ★★★ | Keep, not export |
| ★★ | Weak |
| ★ | Reference only |
| ✗ | Rejected |

---

## Tags

Keep the tag hierarchy flat and small. Three categories are sufficient:

```
Tags/
├── Subject/
│   ├── Street
│   ├── Portrait
│   ├── Architecture
│   ├── Landscape
│   └── Still Life
├── Mood/
│   ├── B&W
│   └── Color
└── Status/
    ├── Portfolio
    └── Published
```

**Rules:**
- Apply `Status/Portfolio` to images promoted to the Portfolio folder.
- Apply `Status/Published` after sharing to social.
- Apply Subject and Mood tags sparingly — only when they add search value.
- Do NOT tag every image. Tag only when you need to find things by that dimension.

---

## Search Workflow

Use digiKam's **Advanced Search** (`Ctrl+F4`) for most queries:

| Goal | Search |
|------|--------|
| Find all ★5 images | Rating = 5 |
| Find Tokyo sessions | Album name contains "Tokyo" |
| Find all portraits | Tag contains "Portrait" |
| Find unpublished ★4+ | Rating ≥ 4 AND NOT tag "Published" |
| Find images from a date range | Date between YYYY-MM-DD and YYYY-MM-DD |

Save frequent searches as **Named Searches** in digiKam for one-click access.

---

## Saved Searches (set up on first run)

| Name | Criteria |
|------|----------|
| Portfolio Candidates | Rating = 5 |
| Export Queue | Rating = 4 |
| Recent Sessions | Date within last 30 days |
| Unpublished | Rating ≥ 4, NOT tag Published |

---

## Maintenance

- After each import: let digiKam rescan (it does this automatically if monitoring is enabled).
- After each darktable editing session: `Album → Rescan for new images` to pick up new `.xmp` changes.
- Monthly: run `Album → Sync metadata with files` to ensure ratings are consistent.

---

## What digiKam Does NOT Do

- **Edit RAW** — use darktable for all editing.
- **Store canonical ratings** — `.xmp` sidecar is the canonical source; digiKam reads from it.
- **Manage exports** — export management is handled by `photo export` script and darktable.
