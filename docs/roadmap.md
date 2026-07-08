# Roadmap

This roadmap defines the incremental evolution of `photo-os` from a documentation skeleton to a fully automated workflow system.

Each version is self-contained and usable — no version is a dead end.

---

## v0.1 — Foundation (current)

**Goal:** Establish conventions, documentation, and repository structure.

**Deliverables:**
- [x] README.md with full workflow overview
- [x] `docs/workflow.md` — end-to-end workflow description
- [x] `docs/folder-convention.md` — folder naming rules
- [x] `docs/darktable.md` — darktable setup and workflow
- [x] `docs/digikam.md` — digiKam setup and workflow
- [x] `docs/portfolio.md` — portfolio curation SOP
- [x] `docs/scripts.md` — planned CLI design
- [x] `docs/roadmap.md` — this file
- [x] `templates/session-notes.md` — shoot session notes template
- [x] `presets/` directory structure for darktable styles
- [x] Initialize git repository and push to GitHub

**Manual workflow:** Everything done by hand following the docs.

---

## v0.2 — Core Scripts

**Goal:** Automate the most repetitive tasks: session creation, import, and backup.

**Deliverables:**
- [x] `scripts/photo` — main CLI dispatcher
- [x] `scripts/lib/common.sh` — shared utility functions (logging, config, path resolution)
- [x] `scripts/commands/new.sh` — `photo new`
- [x] `scripts/commands/import.sh` — `photo import`
- [x] `scripts/commands/backup.sh` — `photo backup`
- [x] `scripts/commands/status.sh` — `photo status`
- [x] `~/.photo-os/config` auto-generation on first run
- [x] Installation instructions in README

**Milestone:** Import a memory card with a single command.

---

## v0.3 — Export & darktable Integration

**Goal:** Automate darktable export via CLI.

**Deliverables:**
- [ ] `scripts/commands/export.sh` — `photo export`
- [ ] `scripts/commands/review.sh` — `photo review`
- [ ] darktable export presets (web, print, instagram) in `presets/darktable/`
- [ ] darktable base style in `presets/darktable/styles/`
- [ ] darktable-cli integration tested end-to-end
- [ ] Export XMP rating filter (only ★4+)

**Milestone:** Full pipeline from import to JPEG export with one command per stage.

---

## v1.0 — Production Ready

**Goal:** Stable, tested, documented workflow suitable for long-term daily use.

**Deliverables:**
- [ ] All v0.2 and v0.3 scripts hardened and tested
- [ ] Error handling: clear messages for all failure modes
- [ ] `photo doctor` — checks system dependencies and config health
- [ ] `photo log` — view import and export history
- [ ] Full uninstall/removal instructions
- [ ] CHANGELOG.md
- [ ] Tested on clean macOS install

**Milestone:** Can onboard a new machine in under 30 minutes.

---

## Future (Post v1.0)

These are tracked ideas, not committed work. Implement when a clear need arises.

| Idea | Notes |
|------|-------|
| `photo publish` | Upload to Instagram via API or shortcut |
| Cloud backup integration | `rclone` to Backblaze B2 or S3 |
| EXIF statistics dashboard | Sessions, gear usage, focal lengths over time |
| AI-assisted culling | Pre-filter technically broken shots |
| Web gallery generation | Static HTML from Portfolio folder |
| Mobile companion | View portfolio on iPhone |

---

## Version History

| Version | Date | Notes |
|---------|------|-------|
| v0.1 | 2025-07-08 | Initial repository structure and documentation |
| v0.2 | 2026-07-08 | Core CLI: photo new, import, backup, status |
