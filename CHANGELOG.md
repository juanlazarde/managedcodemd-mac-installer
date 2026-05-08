# Changelog

All notable changes to this project will be documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.0] - 2026-05-07

### Added
- `install.sh` — installs Homebrew, .NET 9 SDK, ExifTool, clones and builds `managedcodemd` CLI
- `create_automator.sh` — creates two macOS Quick Actions:
  - Finder Quick Action for files and folders (recursive, timestamped output)
  - Services menu action for selected text and URLs (saves to `~/Downloads/`)
- macOS notifications reporting conversion results
- Support for PDF, DOCX, XLSX, PPTX, HTML, images, CSV, JSON, XML, TXT, RTF, OD*, ZIP, WAV, MP3
