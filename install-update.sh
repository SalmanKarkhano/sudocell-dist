#!/bin/bash
# SudoCell Update Script v0.2.0
# Downloads and installs the latest bytecode
# Keeps database and user data intact

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "❌ This script must be run as root (use sudo)"
  exit 1
fi

echo ""
echo "=========================================="
echo "  SudoCell Update v0.2.0"
echo "=========================================="
echo ""

LIB_DIR="/opt/sudocell/lib"
REPO="https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main"

# Array of bytecode files to update (v0.2.0)
FILES=(
  "sudocell_cli.cpython-310.pyc"
  "sudocell_auth.cpython-310.pyc"
  "sudocell_core.cpython-310.pyc"
  "sudocell_ftp.cpython-310.pyc"
  "feature_static_website.cpython-310.pyc"
  "feature_database_creator.cpython-310.pyc"
)

# Verify installation exists
if [[ ! -d "$LIB_DIR" ]]; then
  echo "❌ SudoCell is not installed. Run:"
  echo "   curl -fsSL https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/install.sh | sudo bash"
  exit 1
fi

# Backup old files
echo "📦 Backing up current installation..."
mkdir -p "$LIB_DIR/.backup"
cp "$LIB_DIR"/*.pyc "$LIB_DIR/.backup/" 2>/dev/null || true

# Download and install new bytecode
echo "📥 Downloading latest bytecode..."
FAILED=0
for file in "${FILES[@]}"; do
  if curl -fsSL -o "$LIB_DIR/$file" "$REPO/$file" 2>/dev/null; then
    echo "  ✓ $file"
  else
    echo "  ✗ $file (failed)"
    FAILED=1
  fi
done

if [[ $FAILED -eq 1 ]]; then
  echo ""
  echo "⚠️ Some files failed to download. Restoring backup..."
  rm -f "$LIB_DIR"/*.pyc
  cp "$LIB_DIR/.backup"/*.pyc "$LIB_DIR/" 2>/dev/null || true
  echo "❌ Update failed. Original installation restored."
  exit 1
fi

# Fix permissions
chmod 644 "$LIB_DIR"/*.pyc

echo ""
echo "✅ Update complete!"
echo ""
echo "New version:"
sudocell version
echo ""
echo "Test with:"
echo "  sudo sudocell login -u admin<XXXX> -p <PASSWORD>"
echo "  sudo sudocell list-users"
