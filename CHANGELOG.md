# Changelog

All notable changes to this project will be documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Changed
- `install.sh` now asks before running the official Homebrew installer when Homebrew is missing.
- `install.sh` validates the existing `~/.local/share/markitdown` git origin before updating.
- `install.sh` no longer removes a non-git `~/.local/share/markitdown` directory.
- `install.sh` now selects expected publish output names instead of the first executable file.
- `create_automator.sh` now backs up existing workflows with timestamped `.backup.*` suffixes before replacement.
- `create_automator.sh` no longer restarts Finder automatically.

### Fixed
- Finder Quick Action compatibility with macOS `/bin/bash` 3.2.
- Finder Quick Action input handling for both Automator arguments and stdin.
- Text/URL Quick Action now treats selected `http://` and `https://` values as URLs before falling back to stdin text conversion.
- Text/URL Quick Action now reports conversion failures instead of exiting early under `set -e`.

## [1.0.0] - 2026-05-07

### Added
- `install.sh` — installs prerequisites, clones and builds `managedcodemd` CLI
- `create_automator.sh` — creates two macOS Quick Actions:
  - Finder Quick Action for files and folders (recursive, timestamped output)
  - Services menu action for selected text and URLs (saves to `~/Downloads/`)
- macOS notifications reporting conversion results
- Support for PDF, DOCX, XLSX, PPTX, HTML, images, CSV, JSON, XML, TXT, RTF, OD*, ZIP, WAV, MP3
