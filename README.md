# managedcodemd-mac-installer

Install [ManagedCode MarkItDown](https://github.com/managedcode/markitdown) on macOS and wire it up as Finder Quick Actions — convert files, folders, selected text, and URLs to Markdown with a right-click.

---

## What it does

| Script                | Purpose                                                                                                      |
| --------------------- | ------------------------------------------------------------------------------------------------------------ |
| `install.sh`          | Installs prerequisites, clones this installer repo, builds `managedcodemd-convert`, and installs `pptx-notes-md`                   |
| `create_automator.sh` | Creates two macOS Quick Actions in `~/Library/Services/`, backing up existing workflows with the same names |

### Quick Actions installed

| Name                                              | Trigger                                             | Input                | Output                               |
| ------------------------------------------------- | --------------------------------------------------- | -------------------- | ------------------------------------ |
| **Convert to .md with Managedcode**               | Right-click in Finder → Quick Actions               | Files or folders     | `.md` saved next to each source file |
| **Convert to .md with Managedcode (Text & URLs)** | Select text/URL in any app → right-click → Services | Selected text or URL | `~/Downloads/converted_TIMESTAMP.md` |

### Supported file types

PDF, DOCX, XLSX, PPTX, HTML, HTM, JPG, JPEG, PNG, GIF, WEBP, BMP, TIFF, TIF, CSV, JSON, XML, TXT, RTF, ODT, ODS, ODP, ZIP, WAV, MP3

---

## Requirements

- macOS 12 Monterey or later
- [Homebrew](https://brew.sh) (the installer can run the official Homebrew installer after confirmation)
- .NET 10 SDK (installed with Homebrew if missing or older than major version 10)

---

## Installation

```bash
git clone https://github.com/juanlazarde/managedcodemd-mac-installer.git
cd managedcodemd-mac-installer
bash install.sh
bash create_automator.sh
```

Run `install.sh` first — it builds the `managedcodemd-convert` binary that `create_automator.sh` depends on.

If Homebrew is missing, `install.sh` asks before running the official Homebrew installer. Existing data at `~/.local/share/managedcodemd` is not overwritten unless it is the expected installer git clone.

---

## Usage

### Commands

| Command                 | Purpose                                                                 |
| ----------------------- | ----------------------------------------------------------------------- |
| `managedcodemd`         | Reserved for the original wizard command; this installer does not replace it |
| `managedcodemd-convert` | Direct non-interactive conversion command used by the Quick Actions     |
| `pptx-notes-md`         | Extracts PPTX slide content and speaker notes to Markdown               |

```bash
managedcodemd-convert document.pdf
managedcodemd-convert https://example.com/page
cat notes.txt | managedcodemd-convert -
pptx-notes-md deck.pptx
pptx-notes-md folder/
```

### PowerPoint Speaker Notes

`pptx-notes-md deck.pptx` writes `deck.md` next to the source file. If `deck.md` already exists, a timestamp suffix is added.

`pptx-notes-md folder/` recursively processes every `.pptx` under the folder and writes each `.md` next to its source deck.

Use `pptx-notes-md deck.pptx --stdout` to print Markdown instead of writing a file, or `pptx-notes-md deck.pptx -o notes.md` to choose an explicit output file.

### Finder (files & folders)

1. Select one or more files, or a folder, in Finder
2. Right-click → **Quick Actions** → **Convert to .md with Managedcode**
3. A `.md` file appears next to each converted file
   - If a `.md` already exists, a timestamp suffix is added (e.g. `document_20260507_143022.md`)
   - Subfolders are recursed automatically
   - Unsupported file types are skipped and counted in the notification
4. A macOS notification reports how many files were converted, failed, or skipped

### Text & URLs (any app)

1. Select any text or a URL in any application
2. Right-click → **Services** → **Convert to .md with Managedcode (Text & URLs)**
3. Output saved to `~/Downloads/converted_TIMESTAMP.md`
4. A macOS notification confirms the save location

---

## Updating

To update the CLI to the latest version:

```bash
bash install.sh
```

The script pulls the latest source and rebuilds. Re-running `create_automator.sh` is only needed if workflow behaviour changes.

Re-running `create_automator.sh` replaces the installed Quick Actions and moves any existing workflows with the same names to timestamped `.backup.YYYYMMDD_HHMMSS` directories.

---

## Troubleshooting

**Quick Actions don't appear in the menu**
Go to `System Settings → Keyboard → Keyboard Shortcuts → Services` and enable both **Convert to .md with Managedcode** entries.

If they still do not appear, log out and back in, or run:

```bash
/System/Library/CoreServices/pbs -update
```

**`managedcodemd-convert: command not found`**
Add `~/.local/bin` to your PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Conversion fails on a file**
Check that the file type is in the supported list above. For unsupported types, `managedcodemd-convert` will skip the file and report it in the notification.

**PPTX notes are missing from general conversion**
Use `pptx-notes-md` for PowerPoint decks when speaker notes are required. MarkItDown-based PPTX conversion may not include the notes pane.

**Installer refuses to use `~/.local/share/managedcodemd`**
The installer only updates that path when it is the expected installer git clone. If the path contains other data, move it aside or remove it before running `install.sh`.

---

## Uninstall

```bash
# Remove CLI
rm -f ~/.local/bin/managedcodemd-convert
rm -f ~/.local/bin/pptx-notes-md
rm -rf ~/.local/share/managedcodemd

# Remove Quick Actions
rm -rf ~/Library/Services/Convert\ to\ .md\ with\ Managedcode.workflow
rm -rf ~/Library/Services/Convert\ to\ .md\ with\ Managedcode\ \(Text\ \&\ URLs\).workflow

# Optional: remove workflow backups created by create_automator.sh
rm -rf ~/Library/Services/Convert\ to\ .md\ with\ Managedcode.workflow.backup.*
rm -rf ~/Library/Services/Convert\ to\ .md\ with\ Managedcode\ \(Text\ \&\ URLs\).workflow.backup.*
```

---

## License

MIT — see [LICENSE](LICENSE).
