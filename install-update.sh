#!/bin/bash
# SudoCell Update Script
# Downloads and installs the latest .deb release
# Keeps database and user data intact

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "❌ This script must be run as root (use sudo)"
  exit 1
fi

echo ""
echo "=========================================="
echo "  SudoCell Update"
echo "=========================================="
echo ""

REPO_OWNER="SalmanKarkhano"
REPO_NAME="sudocell-dist"
RELEASE_API="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"

echo "🔄 Fetching latest release..."

# Get latest release info
RELEASE_INFO=$(curl -fsSL "$RELEASE_API" 2>/dev/null)
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o '"browser_download_url": "[^"]*\.deb"' | head -1 | cut -d'"' -f4)
VERSION=$(echo "$RELEASE_INFO" | grep -o '"tag_name": "[^"]*"' | head -1 | cut -d'"' -f4)

if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "❌ Failed to fetch latest release."
  exit 1
fi

echo "✓ Found version: $VERSION"
echo "📦 Downloading: $DOWNLOAD_URL"

# Download to temp file
TEMP_DEB=$(mktemp)
trap "rm -f $TEMP_DEB" EXIT

if ! curl -fsSL -o "$TEMP_DEB" "$DOWNLOAD_URL"; then
  echo "❌ Failed to download release."
  exit 1
fi

echo "✓ Download complete"
echo "📝 Installing..."

# Stop service before upgrade
if systemctl is-active --quiet sudocell 2>/dev/null; then
  echo "  Stopping sudocell service..."
  systemctl stop sudocell
fi

# Install the .deb
if ! dpkg -i "$TEMP_DEB"; then
  echo "❌ Installation failed."
  exit 1
fi

echo ""
echo "✅ Update complete!"
echo ""
echo "New version:"
sudocell version
echo ""
echo "Starting service..."
systemctl start sudocell
echo ""
echo "Test with:"
echo "  sudo sudocell login -u admin<XXXX> -p <PASSWORD>"
echo "  sudo sudocell list-users"
