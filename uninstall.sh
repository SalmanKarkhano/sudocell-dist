#!/usr/bin/env bash
# SudoCell Uninstaller
# Uninstall command: sudo bash uninstall.sh

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "This uninstaller must be run as root (use sudo)."
  exit 1
fi

INSTALL_DIR="/opt/sudocell"
ETC_DIR="/etc/sudocell"
DATA_DIR="/var/lib/sudocell"
LOG_DIR="/var/log/sudocell"

echo ""
echo "=========================================="
echo "  SudoCell Uninstaller"
echo "=========================================="
echo ""

# Check if SudoCell is installed
if [[ ! -d "$INSTALL_DIR" ]] && ! dpkg -l | grep -q "sudocell"; then
  echo "SudoCell does not appear to be installed."
  exit 0
fi

# Confirm uninstallation
read -p "Are you sure you want to uninstall SudoCell? This will remove all data. (y/n): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Uninstallation cancelled."
  exit 0
fi

echo ""
echo "=========================================="
echo "  Uninstalling SudoCell..."
echo "=========================================="
echo ""

# Step 1: Stop service
echo "Stopping SudoCell service..."
systemctl stop sudocell 2>/dev/null || true
systemctl disable sudocell 2>/dev/null || true
echo "[OK] Service stopped and disabled"

# Step 2: Remove package
echo ""
echo "Removing SudoCell package..."
dpkg -r sudocell 2>/dev/null || true
echo "[OK] Package removed"

# Step 3: Clean up directories
echo ""
echo "Cleaning up directories..."
rm -rf "$INSTALL_DIR" 2>/dev/null || true
rm -rf "$ETC_DIR" 2>/dev/null || true
rm -rf "$DATA_DIR" 2>/dev/null || true
rm -rf "$LOG_DIR" 2>/dev/null || true
echo "[OK] Directories removed"

# Step 4: Remove systemd service file if it exists elsewhere
if [[ -f /etc/systemd/system/sudocell.service ]]; then
  rm -f /etc/systemd/system/sudocell.service
  systemctl daemon-reload
fi

# Step 5: Remove sudocell command from PATH if it's a symlink
if [[ -L /usr/local/bin/sudocell ]]; then
  rm -f /usr/local/bin/sudocell
fi

echo ""
echo "=========================================="
echo "Uninstallation Complete!"
echo "=========================================="
echo ""
echo "SudoCell has been successfully removed from your system."
echo ""
