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

# Download from sudocell-dist repository main branch
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

# Generate random admin credentials
ADMIN_USER="admin$(openssl rand -hex 2)"
ADMIN_PASS=$(openssl rand -base64 12)
ADMIN_EMAIL="admin@sudocell.local"

rm -f "$TEMP_DEB"

# Start service
systemctl daemon-reload
systemctl enable sudocell
systemctl start sudocell

# Wait for service to be ready
sleep 2

# Create admin user in database
echo "Setting up admin account..."
python3 << PYTHON 2>/dev/null || true
import sys
import os
import sqlite3
import hashlib
import bcrypt

try:
    db_path = "/etc/sudocell/users.db"
    os.makedirs("/etc/sudocell", exist_ok=True)
    os.chmod("/etc/sudocell", 0o700)

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Create tables if not exists
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            is_admin INTEGER DEFAULT 0,
            system_user INTEGER DEFAULT 0
        )
    """)

    # Hash password with bcrypt or fallback to PBKDF2
    password = "$ADMIN_PASS".encode()
    try:
        import bcrypt as bcrypt_module
        password_hash = bcrypt_module.hashpw(password, bcrypt_module.gensalt(12)).decode()
    except:
        password_hash = hashlib.pbkdf2_hmac('sha256', password, b'sudocell-salt', 100000).hex()

    # Create admin user
    cursor.execute("""
        INSERT OR IGNORE INTO users (username, email, password_hash, is_admin, system_user)
        VALUES (?, ?, ?, ?, ?)
    """, ("$ADMIN_USER", "$ADMIN_EMAIL", password_hash, 1, 0))

    conn.commit()
    conn.close()
    os.chmod(db_path, 0o600)
except:
    pass
PYTHON

# Success message with credentials
echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║     ✓ SudoCell v0.0.1 Installed Successfully!      ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""
echo "Your Admin Credentials:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Username: $ADMIN_USER"
echo "  Password: $ADMIN_PASS"
echo "  Email:    $ADMIN_EMAIL"
echo ""
echo "Quick Start:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  1. Login:"
echo "     sudocell login -u $ADMIN_USER -p \"$ADMIN_PASS\""
echo ""
echo "  2. Check status:"
echo "     sudocell whoami"
echo ""
echo "  3. Get help:"
echo "     sudocell --help"
echo ""
echo "Documentation: https://github.com/SalmanKarkhano/sudocell-dist"
echo ""
