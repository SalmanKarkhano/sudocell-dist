#!/usr/bin/env bash
# SudoCell v0.0.1 - One-Click Installer
# Installation: curl -fsSL https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/install.sh | sudo bash

set -euo pipefail

# Check root
if [[ "${EUID}" -ne 0 ]]; then
  echo "Error: This installer must be run as root (use sudo)"
  exit 1
fi

echo "Installing SudoCell v0.0.1..."

# Create directories
mkdir -p /opt/sudocell
mkdir -p /etc/sudocell
mkdir -p /var/lib/sudocell
mkdir -p /var/log/sudocell

# Download from sudocell-dist repository (raw GitHub content)
PACKAGE_URL="https://github.com/SalmanKarkhano/sudocell-dist/raw/main/sudocell_0.0.1_all.deb"
TEMP_DEB=$(mktemp)

echo "Downloading SudoCell package..."
if ! curl -fsSL -o "$TEMP_DEB" "$PACKAGE_URL"; then
  echo "Error: Failed to download package from $PACKAGE_URL"
  exit 1
fi

# Install package
echo "Installing package..."
if ! dpkg -i "$TEMP_DEB"; then
  apt --fix-broken install -y
  dpkg -i "$TEMP_DEB"
fi

rm -f "$TEMP_DEB"

# Start service
systemctl daemon-reload
systemctl enable sudocell
systemctl start sudocell

echo ""
echo "✓ SudoCell v0.0.1 installed successfully!"
echo ""
echo "Next steps:"
echo "  sudocell --help"
echo "  sudocell login -u admin -p password"
echo ""
