# Contributing

## Getting started

1. Fork the repo and clone your fork
2. Create a branch: `git checkout -b my-fix`
3. Make your changes
4. Test on macOS (see below)
5. Open a pull request

## Testing changes

**`install.sh`**
Run on a clean macOS environment or use a VM. Verify:
- `managedcodemd-convert` binary exists at `~/.local/bin/managedcodemd-convert`
- `pptx-notes-md` exists at `~/.local/bin/pptx-notes-md`
- `managedcodemd-convert some-file.pdf` produces output
- `pptx-notes-md some-file.pptx` creates `some-file.md`
- `pptx-notes-md some-folder/` recursively processes PPTX files
- `managedcodemd` is not overwritten by the installer
- Existing non-git data at `~/.local/share/managedcodemd` is not deleted
- Existing git clones with the wrong origin are rejected

**`create_automator.sh`**
- Run the script and verify both `.workflow` bundles appear in `~/Library/Services/`
- Right-click a supported file in Finder and confirm the Quick Action appears
- Select text in any app and confirm the Services menu entry appears
- Re-run the script and verify existing workflows are backed up with `.backup.YYYYMMDD_HHMMSS` suffixes
- Validate generated workflow plists with `plutil -lint`
- Confirm embedded workflow scripts pass `/bin/bash -n`

## Reporting bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md). Include:
- macOS version
- Output of `dotnet --version`
- Full error output from the failing script
- Whether an existing `~/.local/share/managedcodemd` or Quick Action workflow was present before running the script

## Suggesting features

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).

## Code style

- Bash: follow existing style — `set -euo pipefail`, lowercase local variables, `snake_case` functions
- Keep scripts self-contained — no external dependencies beyond what `install.sh` installs
