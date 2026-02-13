#!/bin/bash
# SudoCell Update Script
# Downloads and installs the latest release
# Keeps database and user data intact

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "❌ This script must be run as root (use sudo)"
  exit 1
fi

echo "🔄 Updating SudoCell..."
echo ""

# Download latest release from repository
RELEASE_URL="https://github.com/SalmanKarkhano/sudocell-dist/raw/main/sudocell_0.0.1_all.deb"
TEMP_DEB=$(mktemp)

echo "📥 Downloading latest release..."
if ! curl -fsSL -o "$TEMP_DEB" "$RELEASE_URL"; then
  echo "❌ Failed to download package"
  exit 1
fi

echo "📦 Installing update..."
if ! dpkg -i "$TEMP_DEB"; then
  apt --fix-broken install -y
  dpkg -i "$TEMP_DEB"
fi

rm -f "$TEMP_DEB"

# Restart service to apply updates
echo "🔄 Restarting service..."
systemctl restart sudocell

echo ""
echo "✅ Update complete!"
echo ""
echo "Verify with: sudocell --version"
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
