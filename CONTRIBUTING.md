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
- `managedcodemd` binary exists at `~/.local/bin/managedcodemd`
- `managedcodemd some-file.pdf` produces output

**`create_automator.sh`**
- Run the script and verify both `.workflow` bundles appear in `~/Library/Services/`
- Right-click a supported file in Finder and confirm the Quick Action appears
- Select text in any app and confirm the Services menu entry appears

## Reporting bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md). Include:
- macOS version
- Output of `dotnet --version`
- Full error output from the failing script

## Suggesting features

Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.md).

## Code style

- Bash: follow existing style — `set -euo pipefail`, lowercase local variables, `snake_case` functions
- Keep scripts self-contained — no external dependencies beyond what `install.sh` installs
