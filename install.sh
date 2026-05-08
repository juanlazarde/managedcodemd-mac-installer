#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/juanlazarde/managedcodemd-mac-installer"
INSTALL_DIR="$HOME/.local/share/managedcodemd"
BIN_DIR="$HOME/.local/bin"
BINARY="$BIN_DIR/managedcodemd-convert"
EXPECTED_EXE="managedcodemd-convert"
EXPECTED_DLL="managedcodemd-convert.dll"

echo "==> Installing ManagedCode MarkItDown CLI"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

confirm() {
  local prompt="$1"
  local reply

  if [[ ! -t 0 ]]; then
    return 1
  fi

  read -r -p "$prompt [y/N] " reply
  [[ "$reply" == "y" || "$reply" == "Y" || "$reply" == "yes" || "$reply" == "YES" ]]
}

load_homebrew_env() {
  if command -v brew &>/dev/null; then
    return 0
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# ── Homebrew ────────────────────────────────────────────────────────────────
load_homebrew_env
if ! command -v brew &>/dev/null; then
  echo "==> Homebrew is required and was not found."
  confirm "Install Homebrew by running the official installer from https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh?" \
    || die "Homebrew is required. Install it from https://brew.sh and re-run this script."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_homebrew_env
  command -v brew &>/dev/null || die "Homebrew installed but is not available on PATH."
fi

# ── .NET SDK ─────────────────────────────────────────────────────────────────
if ! command -v dotnet &>/dev/null; then
  echo "==> Installing .NET SDK..."
  brew install --cask dotnet-sdk
fi

DOTNET_VER=$(dotnet --version 2>/dev/null || echo "0")
DOTNET_MAJOR="${DOTNET_VER%%.*}"
if [[ "$DOTNET_MAJOR" -lt 10 ]]; then
  echo "==> Upgrading to .NET 10 SDK (found $DOTNET_VER)..."
  brew install --cask dotnet-sdk
fi

echo "    dotnet $(dotnet --version)"

# ── ExifTool (optional, enhances image metadata) ────────────────────────────
if ! command -v exiftool &>/dev/null; then
  echo "==> Installing ExifTool (optional)..."
  brew install exiftool
fi

# ── Clone / update repo ───────────────────────────────────────────────────
if [[ -d "$INSTALL_DIR/.git" ]]; then
  ORIGIN_URL=$(git -C "$INSTALL_DIR" remote get-url origin 2>/dev/null || true)
  [[ "$ORIGIN_URL" == "$REPO_URL" || "$ORIGIN_URL" == "$REPO_URL.git" ]] \
    || die "$INSTALL_DIR exists but its origin is '$ORIGIN_URL' instead of '$REPO_URL'. Move it aside and re-run."

  echo "==> Updating existing clone at $INSTALL_DIR..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  if [[ -e "$INSTALL_DIR" ]]; then
    die "$INSTALL_DIR already exists and is not a git clone. Move it aside and re-run."
  fi

  echo "==> Cloning $REPO_URL..."
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
fi

# ── Build CLI ────────────────────────────────────────────────────────────────
echo "==> Building CLI..."
RUNTIME="osx-$(uname -m | sed 's/x86_64/x64/')"
(
  cd "$INSTALL_DIR"
  dotnet clean cli/managedcodemd.csproj --configuration Release --nologo -q 2>/dev/null || true
  dotnet publish cli/managedcodemd.csproj \
    --configuration Release \
    --runtime "$RUNTIME" \
    --self-contained true \
    --output "$INSTALL_DIR/publish" \
    --nologo
)

# ── Wire up binary ───────────────────────────────────────────────────────────
mkdir -p "$BIN_DIR"

BUILT_BIN=""
if [[ -x "$INSTALL_DIR/publish/$EXPECTED_EXE" ]]; then
  BUILT_BIN="$INSTALL_DIR/publish/$EXPECTED_EXE"
fi

if [[ -n "$BUILT_BIN" ]]; then
  ln -sf "$BUILT_BIN" "$BINARY"
else
  # Fall back to framework-dependent launcher
  BUILT_DLL="$INSTALL_DIR/publish/$EXPECTED_DLL"
  [[ -f "$BUILT_DLL" ]] || die "Could not find expected published binary '$EXPECTED_EXE' or '$EXPECTED_DLL'."

  cat > "$BINARY" <<EOF
#!/usr/bin/env bash
exec dotnet "$BUILT_DLL" "\$@"
EOF
  chmod +x "$BINARY"
fi

# ── PATH hint ────────────────────────────────────────────────────────────────
SHELL_RC=""
case "$SHELL" in
  */zsh)  SHELL_RC="$HOME/.zshrc" ;;
  */bash) SHELL_RC="$HOME/.bashrc" ;;
esac

PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
if [[ -n "$SHELL_RC" ]] && ! grep -qxF "$PATH_LINE" "$SHELL_RC" 2>/dev/null; then
  echo "" >> "$SHELL_RC"
  echo "# Added by markitdown installer" >> "$SHELL_RC"
  echo "$PATH_LINE" >> "$SHELL_RC"
  echo "==> Added ~/.local/bin to PATH in $SHELL_RC"
  echo "    Run: source $SHELL_RC"
fi

if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  export PATH="$BIN_DIR:$PATH"
fi

# ── Verify ───────────────────────────────────────────────────────────────────
echo ""
echo "==> Installation complete!"
echo "    Binary: $BINARY"
echo ""
echo "Usage:"
echo "    managedcodemd-convert <file-or-url>"
echo "    managedcodemd-convert document.pdf"
echo "    managedcodemd-convert https://example.com/page"
