#!/usr/bin/env bash
# SudoCell Update/Install Script
# Downloads and installs the latest SudoCell release

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "This installer must be run as root (use sudo)."
  exit 1
fi

REPO_OWNER="SalmanKarkhano"
REPO_NAME="sudocell-dist"
RELEASE_API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
INSTALL_DIR="/opt/sudocell"
ETC_DIR="/etc/sudocell"
DATA_DIR="/var/lib/sudocell"
LOG_DIR="/var/log/sudocell"
BIN_DIR="/usr/local/bin"

echo "🔄 Fetching latest SudoCell release..."

# Get latest release info
RELEASE_INFO=$(curl -fsSL "$RELEASE_API_URL")
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o '"browser_download_url": "[^"]*\.deb"' | head -1 | cut -d'"' -f4)
VERSION=$(echo "$RELEASE_INFO" | grep -o '"tag_name": "[^"]*"' | head -1 | cut -d'"' -f4)

if [[ -z "$DOWNLOAD_URL" ]]; then
  echo "❌ Failed to fetch latest release. Check internet connection."
  exit 1
fi

echo "✓ Found version: $VERSION"
echo "📦 Downloading: $DOWNLOAD_URL"

# Download to temp directory
TEMP_DEB=$(mktemp)
trap "rm -f $TEMP_DEB" EXIT

if ! curl -fsSL -o "$TEMP_DEB" "$DOWNLOAD_URL"; then
  echo "❌ Failed to download release."
  exit 1
fi

echo "✓ Download complete"
echo "📝 Installing..."

# Stop service before upgrade
if systemctl is-active --quiet sudocell; then
  echo "  Stopping sudocell service..."
  systemctl stop sudocell
fi

# Install the .deb
if ! dpkg -i "$TEMP_DEB"; then
  echo "❌ Installation failed."
  exit 1
fi

echo "✅ SudoCell updated to $VERSION"
echo "🔃 Starting sudocell service..."
systemctl start sudocell
systemctl status sudocell

echo ""
echo "✨ Update complete! Run 'sudocell --help' to verify."
