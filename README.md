# managedcodemd-mac-installer

Install [ManagedCode MarkItDown](https://github.com/managedcode/markitdown) on macOS and wire it up as Finder Quick Actions — convert files, folders, selected text, and URLs to Markdown with a right-click.

---

## What it does

| Script                | Purpose                                                                                    |
| --------------------- | ------------------------------------------------------------------------------------------ |
| `install.sh`          | Installs prerequisites (Homebrew, .NET 9 SDK, ExifTool) and builds the `managedcodemd` CLI |
| `create_automator.sh` | Creates two macOS Quick Actions in `~/Library/Services/`                                   |

### Quick Actions installed

| Name                                              | Trigger                                             | Input                | Output                               |
| ------------------------------------------------- | --------------------------------------------------- | -------------------- | ------------------------------------ |
| **Convert to .md with Managedcode**               | Right-click in Finder → Quick Actions               | Files or folders     | `.md` saved next to each source file |
| **Convert to .md with Managedcode (Text & URLs)** | Select text/URL in any app → right-click → Services | Selected text or URL | `~/Downloads/converted_TIMESTAMP.md` |

### Supported file types

PDF, DOCX, XLSX, PPTX, HTML, JPG, PNG, GIF, WEBP, BMP, TIFF, CSV, JSON, XML, TXT, RTF, ODT, ODS, ODP, ZIP, WAV, MP3

---

## Requirements

- macOS 12 Monterey or later
- [Homebrew](https://brew.sh) (installed automatically if missing)
- .NET 9 SDK (installed automatically if missing)

---

## Installation

```bash
git clone https://github.com/juanlazarde/managedcodemd-mac-installer.git
cd managedcodemd-mac-installer
bash install.sh
bash create_automator.sh
```

Run `install.sh` first — it builds the `managedcodemd` binary that `create_automator.sh` depends on.

---

## Usage

### Finder (files & folders)

1. Select one or more files, or a folder, in Finder
2. Right-click → **Quick Actions** → **Convert to .md with Managedcode**
3. A `.md` file appears next to each converted file
   - If a `.md` already exists, a timestamp suffix is added (e.g. `document_20260507_143022.md`)
   - Subfolders are recursed automatically
   - Unsupported file types are skipped silently
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

---

## Troubleshooting

**Quick Actions don't appear in the menu**
Go to `System Settings → Keyboard → Keyboard Shortcuts → Services` and enable both **Convert to .md with Managedcode** entries.

**`managedcodemd: command not found`**
Add `~/.local/bin` to your PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Conversion fails on a file**
Check that the file type is in the supported list above. For unsupported types, `managedcodemd` will skip the file and report it in the notification.

---

## Uninstall

```bash
# Remove CLI
rm -f ~/.local/bin/managedcodemd
rm -rf ~/.local/share/markitdown

# Remove Quick Actions
rm -rf ~/Library/Services/Convert\ to\ .md\ with\ Managedcode.workflow
rm -rf ~/Library/Services/Convert\ to\ .md\ with\ Managedcode\ \(Text\ \&\ URLs\).workflow
```

---

## License

MIT — see [LICENSE](LICENSE).
