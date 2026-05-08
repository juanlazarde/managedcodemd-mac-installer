# MarkItDown for macOS

> Convert documents, images, and URLs to Markdown — right from Finder or the command line.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2012%2B-lightgrey?logo=apple)](https://apple.com/macos)
[![.NET](https://img.shields.io/badge/.NET-10-512BD4?logo=dotnet)](https://dotnet.microsoft.com/download)
[![Release](https://img.shields.io/github/v/release/juanlazarde/managedcodemd-mac-installer)](https://github.com/juanlazarde/managedcodemd-mac-installer/releases)

**MarkItDown for macOS** wires up [ManagedCode MarkItDown](https://github.com/managedcode/markitdown) as native macOS Quick Actions and CLI commands. Right-click any file or folder in Finder, or select text or a URL in any app, to instantly convert 20+ formats to Markdown. Prefer the terminal? Use `managedcodemd-convert` or `pptx-notes-md` directly.

→ [Quick Start](#quick-start)

---

## Quick Start

```bash
# 1. Install CLI and dependencies
bash <(curl -fsSL https://raw.githubusercontent.com/juanlazarde/managedcodemd-mac-installer/main/install.sh)

# 2. Create Finder Quick Actions
bash ~/.local/share/managedcodemd/create_automator.sh

# 3. Convert your first file
managedcodemd-convert path/to/document.pdf
```

Done — `document.md` appears next to the source file. To convert via Finder instead, see [Finder Quick Action](#finder-quick-action).

---

## What It Does

- Right-click any file or folder in Finder → convert to Markdown in place
- Select text or a URL in any app → convert via the Services menu → saved to `~/Downloads`
- CLI for scripting, piping, and batch processing
- Specialized PowerPoint extractor that captures slide content **and** speaker notes
- macOS notifications report conversion results (converted / failed / skipped)
- Timestamped output — never overwrites an existing `.md` file by default

### Supported Formats

| Category  | Formats                                    |
| --------- | ------------------------------------------ |
| Documents | PDF, DOCX, PPTX, XLSX, RTF, ODT, ODS, ODP |
| Web       | HTML, HTM                                  |
| Images    | JPG, JPEG, PNG, GIF, WEBP, BMP, TIFF, TIF |
| Data      | CSV, JSON, XML                             |
| Text      | TXT                                        |
| Media     | WAV, MP3                                   |
| Archives  | ZIP                                        |

---

## Prerequisites

| Requirement | Version      | Notes                                                                                  |
| ----------- | ------------ | -------------------------------------------------------------------------------------- |
| macOS       | 12 Monterey+ | Required for Automator Quick Actions                                                   |
| [Homebrew](https://brew.sh) | any | `install.sh` offers to install it automatically |
| [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0) | 10+ | The SDK is required — the runtime alone is not enough |
| [ExifTool](https://exiftool.org) | any | Optional — improves image metadata extraction (`brew install exiftool`) |

---

## Installation

Run `install.sh` — it handles everything:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/juanlazarde/managedcodemd-mac-installer/main/install.sh)
```

What it does, step by step:

1. **Homebrew** — checks if installed; offers to run the official Homebrew installer if missing
2. **.NET SDK** — checks version; upgrades to .NET 10 via Homebrew if needed
3. **ExifTool** — optional; installs via Homebrew if confirmed
4. **Repo** — clones this repo to `~/.local/share/managedcodemd` (or pulls latest if already cloned; validates git origin before touching)
5. **Binary** — builds a self-contained native binary via `dotnet publish`
6. **Symlinks** — creates `~/.local/bin/managedcodemd-convert` and `~/.local/bin/pptx-notes-md`
7. **PATH** — adds `~/.local/bin` to your shell RC file (`~/.zshrc` or `~/.bash_profile`) if not already present

Then create the Quick Actions:

```bash
bash ~/.local/share/managedcodemd/create_automator.sh
```

This writes two workflows to `~/Library/Services/`. If workflows with the same names already exist, they are backed up with a timestamped `.backup.YYYYMMDD_HHMMSS` suffix before being replaced.

---

## Usage

| I want to…                        | Use                                               |
| --------------------------------- | ------------------------------------------------- |
| Convert files or folders in Finder | [Finder Quick Action](#finder-quick-action)       |
| Convert selected text or a URL    | [Text & URL Quick Action](#text--url-quick-action) |
| Convert from the terminal         | [`managedcodemd-convert`](#managedcodemd-convert) |
| Extract PowerPoint speaker notes  | [`pptx-notes-md`](#pptx-notes-md)                |
| Use the interactive wizard        | [`managedcodemd`](#managedcodemd)                 |

---

### Finder Quick Action

1. Select one or more files, or a folder, in Finder
2. Right-click → **Quick Actions** → **Convert to .md with Managedcode**
3. A `.md` file appears next to each converted source file
   - If a `.md` already exists, a timestamp suffix is added (e.g. `document_20260507_143022.md`)
   - Folders are processed recursively
   - Unsupported file types are skipped and counted in the notification
4. A macOS notification reports how many files were converted, failed, or skipped

> **Quick Actions not showing?** Go to `System Settings → Keyboard → Keyboard Shortcuts → Services` and enable both **Convert to .md with Managedcode** entries. See [Troubleshooting](#troubleshooting) for more.

---

### Text & URL Quick Action

1. Select any text or a URL in any application
2. Right-click → **Services** → **Convert to .md with Managedcode (Text & URLs)**
3. The result is saved to `~/Downloads/converted_TIMESTAMP.md`
4. A macOS notification confirms the save path

---

### `managedcodemd-convert`

Direct conversion from the terminal. Accepts a file path, a URL, or stdin (`-`).

```bash
# Convert a file
managedcodemd-convert document.pdf

# Convert a URL
managedcodemd-convert https://example.com/page

# Pipe text
cat notes.txt | managedcodemd-convert -
```

Output is written to stdout. Redirect to save:

```bash
managedcodemd-convert report.docx > report.md
```

---

### `pptx-notes-md`

Extracts slide content **and** speaker notes from PowerPoint files to Markdown. Standard converters often miss the notes pane; this tool reads the OpenXML directly.

```bash
# Single file — writes deck.md next to deck.pptx
pptx-notes-md deck.pptx

# Whole folder — recursively converts every .pptx
pptx-notes-md presentations/

# Print to stdout instead of writing a file
pptx-notes-md deck.pptx --stdout

# Choose an explicit output path
pptx-notes-md deck.pptx -o notes.md

# Overwrite existing output instead of timestamping
pptx-notes-md deck.pptx --force
```

**Output format:** `# filename` → `## Slide N` → `### Slide Content` / `### Speaker Notes` for each slide.

If a `.md` already exists, a timestamp suffix is added unless `--force` is passed.

---

### `managedcodemd`

Reserved for the original interactive wizard command. This installer does not replace it.

---

## Troubleshooting

### `managedcodemd-convert: command not found`

`~/.local/bin` is not on your PATH. Fix:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

If you use bash, replace `~/.zshrc` with `~/.bash_profile`.

---

### Quick Action missing from the Finder right-click menu

Run through these in order:

1. Re-run `bash ~/.local/share/managedcodemd/create_automator.sh`
2. Log out and back in (or reboot)
3. Go to `System Settings → Keyboard → Keyboard Shortcuts → Services` and enable both **Convert to .md with Managedcode** entries
4. Check `System Settings → Privacy & Security → Automation` — Finder may need permission

If the workflow still doesn't appear, force a Services refresh:

```bash
/System/Library/CoreServices/pbs -update
```

---

### `.NET SDK not found` during install

`install.sh` requires the SDK, not just the runtime. Install it manually:

```bash
brew install --cask dotnet-sdk
```

Verify the version after:

```bash
dotnet --version   # should print 10.x.x
```

---

### Conversion fails on a specific file

1. Check that the extension is in the [Supported Formats](#supported-formats) table
2. For image files (JPG, PNG, etc.), install ExifTool for better metadata: `brew install exiftool`
3. Re-run the conversion — if it still fails, the error is printed to stderr and reported in the notification

---

### `pptx-notes-md` outputs empty speaker notes

The file may not have speaker notes. Open it in PowerPoint or Keynote and check the **Notes** pane below each slide. If the pane is empty, there is nothing to extract.

---

### Output file not appearing where expected

The output is saved next to the source file by default. If a `.md` already existed, a timestamped variant was created instead. List recent `.md` files:

```bash
ls -lt *.md | head
```

---

### macOS notification never appears

Automator notifications require permission. Go to `System Settings → Notifications`, find **Script Editor** or **Automator**, and set alerts to **Allow**.

---

### `install.sh` fails on git origin validation

The installer only updates `~/.local/share/managedcodemd` if it recognises the directory as its own git clone. If you placed other data there, move it aside first:

```bash
mv ~/.local/share/managedcodemd ~/.local/share/managedcodemd.bak
bash <(curl -fsSL https://raw.githubusercontent.com/juanlazarde/managedcodemd-mac-installer/main/install.sh)
```

---

### Permission denied creating symlinks in `~/.local/bin`

The directory may not exist. Create it:

```bash
mkdir -p ~/.local/bin
```

Then re-run `install.sh`.

---

### `dotnet publish` fails during install

The SDK must be installed, not just the runtime. Confirm:

```bash
dotnet --version   # must be 10.x.x
dotnet sdk check   # shows installed SDKs
```

If only a runtime is listed, install the full SDK:

```bash
brew install --cask dotnet-sdk
```

---

## FAQ

**Does this work on Intel Macs?**
Yes. The binary is compiled as self-contained and runs on both Intel and Apple Silicon.

**Will it overwrite my existing `.md` files?**
No — by default, output gets a timestamp suffix if the target already exists (e.g. `document_20260507_143022.md`). Pass `--force` to overwrite.

**Can I convert a whole folder at once?**
Yes — both the Finder Quick Action and `pptx-notes-md folder/` handle directories recursively. `managedcodemd-convert` processes one file or URL at a time.

**How do I update to a new version?**
Re-run `install.sh`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/juanlazarde/managedcodemd-mac-installer/main/install.sh)
```

It pulls the latest source and rebuilds the binary. Re-running `create_automator.sh` is only needed if the Quick Action behaviour changed.

**Why is `pptx-notes-md` separate from `managedcodemd-convert`?**
`managedcodemd-convert` extracts visible slide content via the ManagedCode library. `pptx-notes-md` also captures the hidden speaker notes pane, which requires reading the OpenXML package directly. They complement each other.

**What happens to images embedded in documents?**
The converter generates best-effort alt text. Installing ExifTool (`brew install exiftool`) improves metadata extraction for standalone image files.

**Is my data sent anywhere?**
No. All conversion happens locally on your machine. No network requests are made except when converting a URL (which fetches only that URL).

---

## Uninstall

```bash
# Remove CLI tools
rm -f ~/.local/bin/managedcodemd-convert
rm -f ~/.local/bin/pptx-notes-md
rm -rf ~/.local/share/managedcodemd

# Remove Quick Actions
rm -rf ~/Library/Services/Convert\ to\ .md\ with\ Managedcode.workflow
rm -rf ~/Library/Services/Convert\ to\ .md\ with\ Managedcode\ \(Text\ \&\ URLs\).workflow

# Remove Quick Action backups (optional)
rm -rf ~/Library/Services/Convert\ to\ .md\ with\ Managedcode.workflow.backup.*
rm -rf ~/Library/Services/Convert\ to\ .md\ with\ Managedcode\ \(Text\ \&\ URLs\).workflow.backup.*
```

To remove the PATH entry added by `install.sh`, open your shell RC file (`~/.zshrc` or `~/.bash_profile`) and delete the line:

```
export PATH="$HOME/.local/bin:$PATH"
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, coding style, and the pull request process.

---

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.
