# digiKam

digiKam is the photo manager in this workflow. It sits between import and editing:

- **Browse** the session after import
- **Rate** images with stars
- **Cull** — reject technically broken shots, identify the best candidates

digiKam does **not** edit RAW files. It does not decide what gets exported. It is a fast, keyboard-driven review tool.

---

## Setup

### 1. Add the photo library

`Settings → Configure digiKam → Collections → Add Collection`

Point it at `~/Photography`. digiKam will scan and index all images automatically.

### 2. Enable XMP sidecar sync

`Settings → Metadata → Behavior`
- **Read metadata from sidecar files:** always
- **Write metadata to sidecar files:** always

This is essential. Ratings set in digiKam must be visible in darktable, and vice versa. Both tools share the same `.xmp` files — there is only one source of truth.

---

## Album Structure

Albums in digiKam mirror the filesystem. No manual album creation is needed.

```
Photography/RAW/2026/2026-07-08 Taipei Blue Hour/   ← Album
```

The session naming convention (`YYYY-MM-DD Project`) makes every album self-describing and chronologically sorted.

---

## Rating System

Ratings are written to `.xmp` sidecar files and shared between digiKam and darktable. The `xmp:Rating` field is an XMP standard — both tools read and write the same value in the same file.

**Rating drives export.** `photo export web` reads `xmp:Rating` from each sidecar and exports only images that meet the threshold (default: ★5). Rating in digiKam is the selection mechanism — not `.xmp` existence, not darktable selection.

| Rating | Meaning | Exported by `photo export`? |
|--------|---------|----------------------------|
| ★★★★★ | Ready to export | **Yes** (default threshold) |
| ★★★★ | Candidate — needs review | Only with `--rating 4` |
| ★★★ | Keep only — do not export | No |
| ★★ | Weak | No |
| ★ | Reference only | No |
| ✗ | Rejected | Never |

**Target per session:** ≤20 images rated ★4 or ★5.

---

## Culling Workflow

A fast three-pass process:

**Pass 1 — Reject technical failures** (blur, wrong exposure, eyes closed)
- Use keyboard: `R` to reject, arrow keys to advance
- Goal: clear out the obvious failures quickly

**Pass 2 — Rate survivors 1–3**
- Filter to non-rejected images
- Assign ★1–3 based on composition and subject

**Pass 3 — Identify the best**
- Filter to ★3+
- Promote the strongest images to ★4 or ★5
- Be selective: ★4 means "candidate", ★5 means "ready to export"

---

## Tags (Optional)

Tags are optional. The date-based folder structure handles most navigation needs.

Add tags only when they add search value that the folder name doesn't provide:

```
Subject/Street
Subject/Portrait
Subject/Architecture
Subject/Landscape
```

Do not create a deep tag taxonomy. If you can find the image by searching the album name, a tag is redundant.

---

## Searching

Use **Advanced Search** (`Ctrl+F4`) for cross-session queries:

| Goal | Criteria |
|------|----------|
| All portfolio candidates | Rating = 5 |
| Export queue | Rating = 4 |
| Recent sessions | Date within last 30 days |
| All street photos | Tag contains "Street" |

Save frequent searches as **Named Searches** for one-click access.

---

## Maintenance

- **After each import:** digiKam rescans automatically if collection monitoring is on.
- **After a darktable session:** `Album → Rescan for new images` picks up new `.xmp` changes.
- **Monthly:** `Album → Sync metadata with files` to confirm ratings are consistent.
