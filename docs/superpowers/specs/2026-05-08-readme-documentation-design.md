# README Documentation Design

**Date:** 2026-05-08
**Scope:** Full restructure and expansion of README.md for end users
**Approach:** Option B — Full Structured Rewrite

---

## Goal

Produce an "amazing" end-user README that a new visitor can land on and immediately understand what the project does, how to install it, and how to use it — with enough troubleshooting and FAQ coverage to be self-sufficient.

## Audience

macOS users who want to convert documents, images, and URLs to Markdown. Not developers or contributors (those are served by CONTRIBUTING.md).

## Constraints

- All documentation stays in README.md (no docs/ folder)
- Existing content is preserved and improved, not discarded
- Must render correctly on GitHub (CommonMark, no custom extensions)
- No video/GIF assets (out of scope for this pass)

---

## Information Hierarchy

Sections in order, designed for top-to-bottom reading:

1. **Hero** — project name + one-sentence tagline
2. **Badges** — License · Platform · .NET version · Latest Release (shields.io)
3. **Quick Start** — 3 steps: install → create Quick Actions → convert first file
4. **What It Does** — features overview + supported formats table
5. **Prerequisites** — macOS 12+, Homebrew, .NET 10 SDK, ExifTool (optional)
6. **Installation** — install.sh walkthrough with narration of each step
7. **Usage** — organized by workflow:
   - Finder Quick Action (right-click files/folders)
   - Text & URL Quick Action (selected text in any app)
   - CLI: `managedcodemd-convert`
   - CLI: `pptx-notes-md` (PowerPoint speaker notes, with full flag reference)
   - CLI: `managedcodemd` (original wizard)
8. **Troubleshooting** — 10 cases with diagnosis and fix
9. **FAQ** — 7 questions
10. **Uninstall** — checklist: symlinks → repo dir → Quick Actions → PATH entry
11. **Contributing** — one sentence linking to CONTRIBUTING.md
12. **License** — MIT one-liner

---

## Hero + Badges

**Title:** `# MarkItDown for macOS`

**Tagline:** `> Convert documents, images, and URLs to Markdown — right from Finder or the command line.`

**Intro paragraph (2–3 sentences):** Explains the two usage modes (Finder right-click + CLI), mentions 20+ supported formats, links to Quick Start.

**Badges (shields.io):**
- `[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)`
- `[![Platform](https://img.shields.io/badge/platform-macOS%2012%2B-lightgrey?logo=apple)](https://apple.com/macos)`
- `[![.NET](https://img.shields.io/badge/.NET-10-512BD4?logo=dotnet)](https://dotnet.microsoft.com/download)`
- `[![Release](https://img.shields.io/github/v/release/juanlazarde/managedcodemd-mac-installer)](https://github.com/juanlazarde/managedcodemd-mac-installer/releases)`

---

## Quick Start

Three copy-pasteable steps to get from zero to working:

```
# 1. Install
bash <(curl -fsSL https://raw.githubusercontent.com/juanlazarde/managedcodemd-mac-installer/main/install.sh)

# 2. Create Quick Actions
bash create_automator.sh

# 3. Convert your first file
managedcodemd-convert path/to/file.pdf
```

---

## What It Does

**Features list:**
- Right-click any file or folder in Finder to convert to Markdown
- Select text or a URL in any app and convert via the Services menu
- CLI for scripting, piping, and batch processing
- Specialized PowerPoint extractor that captures speaker notes
- macOS notifications for conversion results
- Timestamped output — never overwrites existing files by default

**Supported formats table:**

| Category | Formats |
|---|---|
| Documents | PDF, DOCX, PPTX, XLSX, RTF, ODT, ODS, ODP |
| Web | HTML, HTM |
| Images | JPG, JPEG, PNG, GIF, WEBP, BMP, TIFF, TIF |
| Data | CSV, JSON, XML |
| Text | TXT |
| Media | WAV, MP3 |
| Archives | ZIP |

---

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| macOS | 12 Monterey+ | Required for Quick Actions |
| Homebrew | any | `install.sh` offers to install if missing |
| .NET SDK | 10+ | Runtime alone is not enough |
| ExifTool | any | Optional — improves image metadata |

Install links included for each.

---

## Installation

Narrated walkthrough of what `install.sh` does at each step:
1. Checks/installs Homebrew (with user confirmation)
2. Checks/upgrades .NET SDK to version 10+
3. Installs ExifTool (optional)
4. Clones/updates repo to `~/.local/share/managedcodemd`
5. Builds self-contained native binary via `dotnet publish`
6. Creates symlinks in `~/.local/bin`
7. Adds `~/.local/bin` to PATH in shell RC file if needed

---

## Usage

Organized by what the user wants to accomplish:

### Workflow Table

| I want to… | Use |
|---|---|
| Convert files in Finder | Finder Quick Action |
| Convert selected text/URL | Text & URL Quick Action |
| Convert from terminal | `managedcodemd-convert` |
| Extract PowerPoint notes | `pptx-notes-md` |
| Use interactive wizard | `managedcodemd` |

### Per-workflow content

Each workflow gets:
- One-line description
- Exact invocation / how to trigger
- Concrete example
- Note on output location

**`pptx-notes-md` gets extended coverage:**
- Full flag reference: `-o`, `--stdout`, `--force`
- Example: single file, directory batch, stdout pipe
- Output format description (H1 filename → H2 slides → H3 content/notes)

---

## Troubleshooting

10 cases, each with: symptom → diagnosis → fix

1. `command not found: managedcodemd-convert` — PATH not set; re-source shell RC or open new terminal
2. Quick Action missing from Finder right-click — re-run `create_automator.sh`; log out/in; check Finder in System Settings > Privacy & Security > Automation
3. `.NET SDK not found` during install — manual install: `brew install --cask dotnet-sdk`
4. Conversion fails on a specific file — check supported formats list; install ExifTool for image types
5. `pptx-notes-md` outputs empty notes — verify speaker notes exist in the deck (Notes pane in PowerPoint/Keynote)
6. Output file not appearing in expected location — timestamped variant may exist; check with `ls *.md`
7. Quick Action notification never appears — check macOS notification permissions for Automator in System Settings > Notifications
8. `install.sh` fails on git origin validation — explanation of what the check does; manual workaround
9. Permission denied creating symlinks — ensure `~/.local/bin` exists: `mkdir -p ~/.local/bin`
10. `dotnet publish` fails — ensure .NET 10 SDK installed (not runtime-only); verify with `dotnet --version`

---

## FAQ

7 questions:

1. **Does this work on Intel Macs?** Yes — the binary is self-contained and runs on both Intel and Apple Silicon.
2. **Will it overwrite my existing `.md` files?** No — output is timestamped by default. Use `--force` to overwrite.
3. **Can I convert a whole folder at once?** Yes — both the Finder Quick Action and CLI handle directories recursively.
4. **How do I update to a new version?** Re-run `install.sh` — it pulls the latest code and rebuilds.
5. **Why is `pptx-notes-md` separate from `managedcodemd-convert`?** The main converter extracts visible slide content; `pptx-notes-md` also extracts hidden speaker notes, which requires direct OpenXML parsing.
6. **What happens to images embedded in documents?** Best-effort alt text is generated using ExifTool metadata when available.
7. **Is my data sent anywhere?** No — all conversion happens locally on your machine.

---

## Uninstall

Checklist:
1. Remove symlinks: `rm ~/.local/bin/managedcodemd-convert ~/.local/bin/pptx-notes-md`
2. Remove repo: `rm -rf ~/.local/share/managedcodemd`
3. Remove Quick Actions: `rm -rf ~/Library/Services/"Convert to .md with Managedcode.workflow"` (and Text variant)
4. Remove PATH entry from shell RC file (manual step with instructions)

---

## Contributing + License

**Contributing:** One sentence: "See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, coding style, and the pull request process."

**License:** "Distributed under the MIT License. See [LICENSE](LICENSE) for details."

---

## Out of Scope

- GIFs/screenshots of Quick Action workflows (future pass)
- `docs/` folder or separate pages
- Developer/architecture documentation
- API reference for the C# converter integration
