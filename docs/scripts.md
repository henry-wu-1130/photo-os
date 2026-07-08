# Scripts Reference

All automation is provided through a single `photo` CLI entry point.

Install: `ln -sf ~/photo-os/scripts/photo /usr/local/bin/photo`

---

## Usage

```
photo <command> [arguments]

Commands:
  new      Create a new shoot session folder
  import   Import RAW files from memory card
  export   Export edited images to JPEG
  backup   Sync library to backup destinations
  review   Open an export folder in Finder
  status   Show library summary
  help     Show this help message
```

---

## Commands

### `photo new`

**Purpose:** Create a new session folder under `RAW/YYYY/`.

**Usage:**
```sh
photo new "2025-06-15 Tokyo Street"
```

**What it does:**
1. Parses date from session name.
2. Creates `$PHOTO_ROOT/RAW/YYYY/YYYY-MM-DD Location Theme/`.
3. Prints the full path.

**Design notes:**
- Session name is quoted string with format `YYYY-MM-DD Location Theme`.
- Fails with a clear error if the folder already exists.
- Does not import files — only creates the directory.

---

### `photo import`

**Purpose:** Copy RAW files from memory card to the library with checksum verification.

**Usage:**
```sh
photo import /Volumes/MEMORY_CARD
photo import /Volumes/MEMORY_CARD --session "2025-06-15 Tokyo Street"
```

**What it does:**
1. Lists `.ARW` files on the source.
2. Resolves the session name:
   - If `--session` is given, uses it directly.
   - If a session already exists for today, asks whether to reuse it.
   - If multiple sessions exist for today, lists them and lets the user pick.
   - Otherwise, prompts for a **project name only** — the date is added automatically.
3. Creates the full session structure via `photo new` if it doesn't exist.
4. Copies files using `rsync --checksum --ignore-existing`.
5. Verifies copy count matches source count.
6. Logs import summary to `~/.photo-os/import.log`.
7. Ejects the memory card if source is under `/Volumes/`.

**Interactive example (no existing session):**
```
[photo] Found 127 .ARW file(s) in /Volumes/MEMORY_CARD
[photo] Project name: Taipei Blue Hour
[photo] ✓ RAW:       ~/Photography/RAW/2026/2026-07-08 Taipei Blue Hour
[photo] ✓ Export:    ~/Photography/Export/2026-07-08 Taipei Blue Hour (web/ print/)
[photo] ✓ Portfolio: ~/Photography/Portfolio/2026-07-08 Taipei Blue Hour
[photo] Copying to .../2026-07-08 Taipei Blue Hour ...
[photo] ✓ Import complete: 127 / 127 file(s)
```

**Interactive example (session already exists for today):**
```
[photo] Found 43 .ARW file(s) in /Volumes/MEMORY_CARD
[photo] Existing session for today: 2026-07-08 Taipei Blue Hour
[photo] Reuse it? [Y/n]
```

**Flags:**
- `--session` — bypass prompts; use this exact session name
- `--dry-run` — show what would happen without copying anything
- `--no-eject` — skip ejecting the memory card after import

---

### `photo export`

**Purpose:** Export darktable-edited images (★4+) to JPEG.

**Usage:**
```sh
photo export "2025-06-15 Tokyo Street"
photo export "2025-06-15 Tokyo Street" --preset web
photo export "2025-06-15 Tokyo Street" --preset print
photo export "2025-06-15 Tokyo Street" --preset instagram
```

**What it does:**
1. Locates session folder under `RAW/YYYY/`.
2. Finds all `.ARW` files with `.xmp` sidecar rated ★4+.
3. Calls `darktable-cli` with the specified export preset.
4. Outputs to `Export/YYYY-MM-DD Location Theme/web/` (or `print/`).

**Flags:**
- `--preset` — `web` (default), `print`, or `instagram`
- `--rating` — minimum rating (default: 4)
- `--dry-run` — list images that would be exported

**Requires:** `darktable-cli` installed and in PATH.

---

### `photo backup`

**Purpose:** Sync photo library to backup destinations.

**Usage:**
```sh
photo backup
photo backup --dest primary
photo backup --dest secondary
photo backup --verify
```

**What it does:**
1. Reads `BACKUP_PRIMARY` and `BACKUP_SECONDARY` from config.
2. Runs `rsync -av --checksum` from `$PHOTO_ROOT` to destination.
3. Logs transfer summary.

**Flags:**
- `--dest` — `primary`, `secondary`, or `all` (default: all)
- `--dry-run` — show what would be synced
- `--verify` — run checksum verification pass after sync

**Note:** Does not delete from destination. Backup is append-only.

---

### `photo review`

**Purpose:** Open a session's export folder in Finder for review.

**Usage:**
```sh
photo review "2025-06-15 Tokyo Street"
photo review "2025-06-15 Tokyo Street" --preset print
```

**What it does:**
1. Resolves the export folder path.
2. Opens the folder in macOS Finder (`open`).

---

### `photo status`

**Purpose:** Show a summary of the library.

**Usage:**
```sh
photo status
```

**Output example:**
```
Library: /Users/you/Photography
Sessions: 47
RAW files: 8,231 (412 GB)
Exports: 1,204 (18 GB)
Portfolio images: 23

Last import: 2025-06-15 Tokyo Street (127 files)
Last backup: 2025-06-14 22:31 → /Volumes/BackupDrive
```

---

## Config

Scripts read from `~/.photo-os/config`:

```sh
PHOTO_ROOT="$HOME/Photography"
BACKUP_PRIMARY="/Volumes/BackupDrive/Photography"
BACKUP_SECONDARY=""
```

Created automatically with defaults on first run of any `photo` command.

---

## Implementation Notes

- All scripts: POSIX sh compatible, tested on macOS zsh.
- Shared functions in `scripts/lib/common.sh`.
- Each command in `scripts/commands/<command>.sh`.
- `scripts/photo` is the entry point dispatcher.
- No dependencies beyond standard macOS tools + `rsync` + `darktable-cli`.
