#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/managedcode/markitdown"
INSTALL_DIR="$HOME/.local/share/markitdown"
BIN_DIR="$HOME/.local/bin"
BINARY="$BIN_DIR/managedcodemd"

echo "==> Installing ManagedCode MarkItDown CLI"

# ── Homebrew ────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# ── .NET SDK ─────────────────────────────────────────────────────────────────
if ! command -v dotnet &>/dev/null; then
  echo "==> Installing .NET SDK..."
  brew install --cask dotnet-sdk
fi

DOTNET_VER=$(dotnet --version 2>/dev/null || echo "0")
DOTNET_MAJOR="${DOTNET_VER%%.*}"
if [[ "$DOTNET_MAJOR" -lt 9 ]]; then
  echo "==> Upgrading to .NET 9 SDK (found $DOTNET_VER)..."
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
  echo "==> Updating existing clone at $INSTALL_DIR..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "==> Cloning $REPO_URL..."
  rm -rf "$INSTALL_DIR"
  git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
fi

# ── Build CLI ────────────────────────────────────────────────────────────────
echo "==> Building CLI..."
RUNTIME="osx-$(uname -m | sed 's/x86_64/x64/')"
(
  cd "$INSTALL_DIR"
  dotnet clean src/MarkItDown.Cli --configuration Release --nologo -q 2>/dev/null || true
  dotnet publish src/MarkItDown.Cli \
    --configuration Release \
    --runtime "$RUNTIME" \
    --self-contained true \
    --output "$INSTALL_DIR/publish" \
    -p:PublishSingleFile=true \
    -p:IncludeNativeLibrariesForSelfExtract=true \
    --nologo
)

# ── Wire up binary ───────────────────────────────────────────────────────────
mkdir -p "$BIN_DIR"

BUILT_BIN=$(find "$INSTALL_DIR/publish" -maxdepth 1 -type f -perm +111 | head -1)
if [[ -z "$BUILT_BIN" ]]; then
  # Fall back to framework-dependent launcher
  BUILT_BIN=$(find "$INSTALL_DIR/publish" -maxdepth 1 -name "*.dll" | head -1)
  cat > "$BINARY" <<EOF
#!/usr/bin/env bash
exec dotnet "$BUILT_BIN" "\$@"
EOF
  chmod +x "$BINARY"
else
  ln -sf "$BUILT_BIN" "$BINARY"
fi

# ── PATH hint ────────────────────────────────────────────────────────────────
SHELL_RC=""
case "$SHELL" in
  */zsh)  SHELL_RC="$HOME/.zshrc" ;;
  */bash) SHELL_RC="$HOME/.bashrc" ;;
esac

PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
if [[ -n "$SHELL_RC" ]] && ! grep -qF '.local/bin' "$SHELL_RC" 2>/dev/null; then
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
echo "    managedcodemd <file-or-url>"
echo "    managedcodemd document.pdf"
echo "    managedcodemd https://example.com/page"
