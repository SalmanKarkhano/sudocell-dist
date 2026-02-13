#!/bin/bash
# SudoCell Update Script
# Downloads and installs the latest v0.2.0 bytecode
# Keeps database and user data intact

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "❌ This script must be run as root (use sudo)"
  exit 1
fi

echo "🔄 Updating SudoCell to v0.2.0..."
echo ""

LIB_DIR="/opt/sudocell/lib"
REPO="https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main"

# Array of bytecode files to update
FILES=(
  "sudocell_cli.cpython-310.pyc"
  "sudocell_auth.cpython-310.pyc"
  "sudocell_core.cpython-310.pyc"
  "sudocell_ftp.cpython-310.pyc"
  "feature_static_website.cpython-310.pyc"
  "feature_database_creator.cpython-310.pyc"
)

# Backup old files
echo "📦 Backing up old bytecode..."
mkdir -p "$LIB_DIR/.backup"
cp "$LIB_DIR"/*.pyc "$LIB_DIR/.backup/" 2>/dev/null || true

# Download and install new bytecode
echo "📥 Downloading v0.2.0 bytecode..."
for file in "${FILES[@]}"; do
  echo "  - Downloading $file..."
  if ! curl -fsSL -o "$LIB_DIR/$file" "$REPO/$file"; then
    echo "❌ Failed to download $file. Restoring backup..."
    rm -f "$LIB_DIR"/*.pyc
    cp "$LIB_DIR/.backup"/*.pyc "$LIB_DIR/"
    exit 1
  fi
done

# Fix permissions
chmod 644 "$LIB_DIR"/*.pyc

echo ""
echo "✅ Update complete!"
echo ""
echo "Verifying installation..."
sudocell version
echo ""
echo "New commands available:"
sudocell --help 2>&1 | grep -E "^\s+(create-user|list-users|delete-user)" || echo "  (Run with sudo for admin commands)"
echo ""
echo "Next steps:"
echo "  sudo sudocell login -u admin455e -p '<password>'"
echo "  sudo sudocell list-users"
