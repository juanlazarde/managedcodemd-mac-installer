#!/usr/bin/env bash
set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
MENU_LABEL="Convert to .md with Managedcode"
WORKFLOW_MARKER="Created by managedcodemd-mac-installer"

SERVICES_DIR="$HOME/Library/Services"
FINDER_WORKFLOW="$SERVICES_DIR/${MENU_LABEL}.workflow"
TEXT_WORKFLOW="$SERVICES_DIR/${MENU_LABEL} (Text & URLs).workflow"

# ── Helpers ───────────────────────────────────────────────────────────────────
backup_existing_workflow() {
  local wf="$1"
  local backup

  [[ -e "$wf" ]] || return 0

  backup="${wf}.backup.$(date +"%Y%m%d_%H%M%S")"
  while [[ -e "$backup" ]]; do
    backup="${backup}.$$"
  done

  mv "$wf" "$backup"
  echo "==> Backed up existing workflow: $backup"
}

# ── Shared conversion logic (embedded in each workflow) ───────────────────────
# This script is embedded inside the Automator workflows as a Run Shell Script action.

FINDER_SHELL_SCRIPT='#!/usr/bin/env bash
set -euo pipefail

MANAGED_CMD="$HOME/.local/bin/managedcodemd-convert"
SUPPORTED_EXTENSIONS=(pdf doc docx xlsx pptx html htm jpg jpeg png gif webp bmp tiff tif csv json xml txt rtf odt ods odp zip wav mp3)
SUCCESS=0
FAIL=0
SKIP=0

ext_supported() {
  local file_ext="${1##*.}"
  file_ext=$(printf "%s" "$file_ext" | tr "[:upper:]" "[:lower:]")
  for e in "${SUPPORTED_EXTENSIONS[@]}"; do
    [[ "$e" == "$file_ext" ]] && return 0
  done
  return 1
}

convert_file() {
  local input="$1"
  local base="${input%.*}"
  local ts
  ts=$(date +"%Y%m%d_%H%M%S")
  local output="${base}.md"
  [[ -f "$output" ]] && output="${base}_${ts}.md"

  if "$MANAGED_CMD" "$input" > "$output" 2>/dev/null; then
    (( SUCCESS++ )) || true
  else
    rm -f "$output"
    (( FAIL++ )) || true
  fi
}

process_path() {
  local path="$1"
  if [[ -d "$path" ]]; then
    while IFS= read -r -d "" file; do
      if ext_supported "$file"; then
        convert_file "$file"
      else
        (( SKIP++ )) || true
      fi
    done < <(find "$path" -type f -print0)
  elif [[ -f "$path" ]]; then
    if ext_supported "$path"; then
      convert_file "$path"
    else
      (( SKIP++ )) || true
    fi
  fi
}

if [[ $# -gt 0 ]]; then
  for path in "$@"; do
    [[ -n "$path" ]] && process_path "$path"
  done
else
  while IFS= read -r line; do
    [[ -n "$line" ]] && process_path "$line"
  done
fi

MSG=""
[[ $SUCCESS -gt 0 ]] && MSG="${SUCCESS} file(s) converted."
[[ $FAIL -gt 0 ]]    && MSG="$MSG ${FAIL} failed."
[[ $SKIP -gt 0 ]]    && MSG="$MSG ${SKIP} unsupported skipped."
[[ -z "$MSG" ]]      && MSG="Nothing to convert."

osascript -e "display notification \"$MSG\" with title \"Convert to .md with Managedcode\""
'

TEXT_SHELL_SCRIPT='#!/usr/bin/env bash
set -euo pipefail

MANAGED_CMD="$HOME/.local/bin/managedcodemd-convert"
OUTPUT_DIR="$HOME/Downloads"
mkdir -p "$OUTPUT_DIR"

INPUT="$(cat)"
[[ -z "$INPUT" ]] && exit 0

TS=$(date +"%Y%m%d_%H%M%S")
OUTPUT="$OUTPUT_DIR/converted_${TS}.md"

is_url() {
  case "$1" in
    http://*|https://*) return 0 ;;
    *) return 1 ;;
  esac
}

CONVERTED=0
if is_url "$INPUT"; then
  if "$MANAGED_CMD" "$INPUT" > "$OUTPUT" 2>/dev/null; then
    CONVERTED=1
  fi
else
  if printf "%s" "$INPUT" | "$MANAGED_CMD" - > "$OUTPUT" 2>/dev/null; then
    CONVERTED=1
  fi
fi

if [[ "$CONVERTED" -eq 1 && -s "$OUTPUT" ]]; then
  osascript -e "display notification \"Saved to Downloads/converted_${TS}.md\" with title \"Convert to .md with Managedcode\""
else
  rm -f "$OUTPUT"
  osascript -e "display notification \"Conversion failed.\" with title \"Convert to .md with Managedcode\""
fi
'

# ── Build Finder workflow (files & folders) ───────────────────────────────────
build_finder_workflow() {
  local wf="$1"
  backup_existing_workflow "$wf"
  mkdir -p "$wf/Contents"

  cat > "$wf/Contents/document.wflow" <<WFLOW
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- $WORKFLOW_MARKER -->
<plist version="1.0">
<dict>
  <key>AMApplicationBuild</key>
  <string>521</string>
  <key>AMApplicationVersion</key>
  <string>2.10</string>
  <key>AMDocumentVersion</key>
  <string>2</string>
  <key>actions</key>
  <array>
    <dict>
      <key>action</key>
      <dict>
        <key>AMAccepts</key>
        <dict>
          <key>Container</key>
          <string>List</string>
          <key>Optional</key>
          <true/>
          <key>Types</key>
          <array>
            <string>com.apple.cocoa.path</string>
          </array>
        </dict>
        <key>AMActionVersion</key>
        <string>2.0.3</string>
        <key>AMApplication</key>
        <array>
          <string>Finder</string>
        </array>
        <key>AMParameterProperties</key>
        <dict>
          <key>COMMAND_STRING</key>
          <dict/>
          <key>CheckedForUserDefaultShell</key>
          <dict/>
          <key>inputMethod</key>
          <dict/>
          <key>shell</key>
          <dict/>
          <key>source</key>
          <dict/>
        </dict>
        <key>AMProvides</key>
        <dict>
          <key>Container</key>
          <string>List</string>
          <key>Types</key>
          <array>
            <string>com.apple.cocoa.path</string>
          </array>
        </dict>
        <key>ActionBundlePath</key>
        <string>/System/Library/Automator/Run Shell Script.action</string>
        <key>ActionName</key>
        <string>Run Shell Script</string>
        <key>ActionParameters</key>
        <dict>
          <key>COMMAND_STRING</key>
          <string>$(echo "$FINDER_SHELL_SCRIPT" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')</string>
          <key>CheckedForUserDefaultShell</key>
          <true/>
          <key>inputMethod</key>
          <integer>1</integer>
          <key>shell</key>
          <string>/bin/bash</string>
          <key>source</key>
          <string></string>
        </dict>
        <key>BundleIdentifier</key>
        <string>com.apple.RunShellScript</string>
        <key>CFBundleVersion</key>
        <string>2.0.3</string>
        <key>CanShowSelectedItemsWhenRun</key>
        <false/>
        <key>CanShowWhenRun</key>
        <true/>
        <key>Category</key>
        <array>
          <string>AMCategoryUtilities</string>
        </array>
        <key>Class Name</key>
        <string>RunShellScriptAction</string>
        <key>InputUUID</key>
        <string>$(uuidgen)</string>
        <key>Keywords</key>
        <array>
          <string>Shell</string>
          <string>Script</string>
          <string>Command</string>
          <string>Run</string>
          <string>Unix</string>
        </array>
        <key>OutputUUID</key>
        <string>$(uuidgen)</string>
        <key>UUID</key>
        <string>$(uuidgen)</string>
        <key>UnlockPassword</key>
        <string></string>
        <key>UserDefinedFields</key>
        <dict/>
        <key>isViewVisible</key>
        <true/>
        <key>location</key>
        <string>309.000000:256.000000</string>
        <key>nibPath</key>
        <string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/English.lproj/main.nib</string>
      </dict>
      <key>isViewVisible</key>
      <true/>
    </dict>
  </array>
  <key>connectors</key>
  <dict/>
  <key>workflowMetaData</key>
  <dict>
    <key>workflowType</key>
    <string>com.apple.automator.servicesMenu</string>
    <key>serviceInputTypeIdentifier</key>
    <string>com.apple.automator.fileSystemObject</string>
    <key>serviceOutputTypeIdentifier</key>
    <string>com.apple.automator.nothing</string>
    <key>serviceProcessesInput</key>
    <integer>0</integer>
    <key>serviceApplicationBundleID</key>
    <string>com.apple.finder</string>
  </dict>
</dict>
</plist>
WFLOW
}

# ── Build Text/URL workflow ───────────────────────────────────────────────────
build_text_workflow() {
  local wf="$1"
  backup_existing_workflow "$wf"
  mkdir -p "$wf/Contents"

  cat > "$wf/Contents/document.wflow" <<WFLOW
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- $WORKFLOW_MARKER -->
<plist version="1.0">
<dict>
  <key>AMApplicationBuild</key>
  <string>521</string>
  <key>AMApplicationVersion</key>
  <string>2.10</string>
  <key>AMDocumentVersion</key>
  <string>2</string>
  <key>actions</key>
  <array>
    <dict>
      <key>action</key>
      <dict>
        <key>AMAccepts</key>
        <dict>
          <key>Container</key>
          <string>List</string>
          <key>Optional</key>
          <true/>
          <key>Types</key>
          <array>
            <string>NSStringPboardType</string>
          </array>
        </dict>
        <key>AMActionVersion</key>
        <string>2.0.3</string>
        <key>AMApplication</key>
        <array>
          <string>Any Application</string>
        </array>
        <key>AMParameterProperties</key>
        <dict>
          <key>COMMAND_STRING</key>
          <dict/>
          <key>CheckedForUserDefaultShell</key>
          <dict/>
          <key>inputMethod</key>
          <dict/>
          <key>shell</key>
          <dict/>
          <key>source</key>
          <dict/>
        </dict>
        <key>AMProvides</key>
        <dict>
          <key>Container</key>
          <string>List</string>
          <key>Types</key>
          <array>
            <string>NSStringPboardType</string>
          </array>
        </dict>
        <key>ActionBundlePath</key>
        <string>/System/Library/Automator/Run Shell Script.action</string>
        <key>ActionName</key>
        <string>Run Shell Script</string>
        <key>ActionParameters</key>
        <dict>
          <key>COMMAND_STRING</key>
          <string>$(echo "$TEXT_SHELL_SCRIPT" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')</string>
          <key>CheckedForUserDefaultShell</key>
          <true/>
          <key>inputMethod</key>
          <integer>1</integer>
          <key>shell</key>
          <string>/bin/bash</string>
          <key>source</key>
          <string></string>
        </dict>
        <key>BundleIdentifier</key>
        <string>com.apple.RunShellScript</string>
        <key>CFBundleVersion</key>
        <string>2.0.3</string>
        <key>CanShowSelectedItemsWhenRun</key>
        <false/>
        <key>CanShowWhenRun</key>
        <true/>
        <key>Category</key>
        <array>
          <string>AMCategoryUtilities</string>
        </array>
        <key>Class Name</key>
        <string>RunShellScriptAction</string>
        <key>InputUUID</key>
        <string>$(uuidgen)</string>
        <key>Keywords</key>
        <array>
          <string>Shell</string>
          <string>Script</string>
          <string>Command</string>
          <string>Run</string>
          <string>Unix</string>
        </array>
        <key>OutputUUID</key>
        <string>$(uuidgen)</string>
        <key>UUID</key>
        <string>$(uuidgen)</string>
        <key>UnlockPassword</key>
        <string></string>
        <key>UserDefinedFields</key>
        <dict/>
        <key>isViewVisible</key>
        <true/>
        <key>location</key>
        <string>309.000000:256.000000</string>
        <key>nibPath</key>
        <string>/System/Library/Automator/Run Shell Script.action/Contents/Resources/English.lproj/main.nib</string>
      </dict>
      <key>isViewVisible</key>
      <true/>
    </dict>
  </array>
  <key>connectors</key>
  <dict/>
  <key>workflowMetaData</key>
  <dict>
    <key>workflowType</key>
    <string>com.apple.automator.servicesMenu</string>
    <key>serviceInputTypeIdentifier</key>
    <string>com.apple.automator.text</string>
    <key>serviceOutputTypeIdentifier</key>
    <string>com.apple.automator.nothing</string>
    <key>serviceProcessesInput</key>
    <integer>0</integer>
  </dict>
</dict>
</plist>
WFLOW
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo "==> Creating Automator Quick Actions..."

mkdir -p "$SERVICES_DIR"
build_finder_workflow "$FINDER_WORKFLOW"
build_text_workflow "$TEXT_WORKFLOW"

# Reload Services so macOS picks them up immediately
/System/Library/CoreServices/pbs -update 2>/dev/null || true

echo ""
echo "==> Done! Two Quick Actions installed:"
echo ""
echo "    1. \"${MENU_LABEL}\""
echo "       Right-click any file(s) or folder in Finder → Quick Actions"
echo "       Output: .md saved next to each source file (timestamped if exists)"
echo ""
echo "    2. \"${MENU_LABEL} (Text & URLs)\""
echo "       Select any text or URL in any app → right-click → Services"
echo "       Output: converted .md saved to ~/Downloads/"
echo ""
echo "    Note: If the menu items don't appear immediately, go to:"
echo "    System Settings → Keyboard → Keyboard Shortcuts → Services"
echo "    and enable both \"${MENU_LABEL}\" entries."
