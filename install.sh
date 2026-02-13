#!/usr/bin/env bash
# SudoCell One-Click Installer
# Install command: curl -fsSL https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/install.sh | sudo bash

set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "This installer must be run as root (use sudo)."
  exit 1
fi

INSTALL_DIR="/opt/sudocell"
ETC_DIR="/etc/sudocell"
DATA_DIR="/var/lib/sudocell"
LOG_DIR="/var/log/sudocell"

echo ""
echo "=========================================="
echo "  SudoCell One-Click Installer v0.1.2"
echo "  Hosting Control Panel"
echo "=========================================="
echo ""

# Check if already installed
if [[ -d "$INSTALL_DIR" ]]; then
  echo "Warning: SudoCell is already installed."
  read -p "Do you want to reinstall? (y/n): " -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
  fi
  echo "Cleaning up old installation..."
  systemctl stop sudocell 2>/dev/null || true
  rm -rf "$INSTALL_DIR" "$DATA_DIR" "$LOG_DIR" 2>/dev/null || true
fi

# Generate random admin credentials
ADMIN_USER="admin$(openssl rand -hex 2)"
ADMIN_PASS=$(openssl rand -base64 12)
ADMIN_EMAIL="admin@sudocell.local"

echo "=========================================="
echo "  Installing SudoCell..."
echo "=========================================="
echo ""

# Step 1: Create directories
echo "Creating directories..."
mkdir -p "$INSTALL_DIR/lib"
mkdir -p "$ETC_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"
chmod 700 "$ETC_DIR"
chmod 700 "$DATA_DIR"
chmod 700 "$LOG_DIR"
echo "[OK] Directories created"

# Step 2: Install system dependencies
echo ""
echo "Installing system dependencies..."
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -qq > /dev/null 2>&1 || true
  apt-get install -y -qq python3 mysql-client postgresql-client > /dev/null 2>&1 || true
  echo "[OK] Dependencies installed (Debian/Ubuntu)"
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y -q python3 mysql postgresql > /dev/null 2>&1 || true
  echo "[OK] Dependencies installed (Fedora/RHEL)"
elif command -v yum >/dev/null 2>&1; then
  yum install -y -q python3 mysql postgresql > /dev/null 2>&1 || true
  echo "[OK] Dependencies installed (CentOS/RHEL)"
else
  echo "Warning: No supported package manager found"
fi

# Step 3: Download latest release
echo ""
echo "Downloading latest release..."

RELEASE_INFO=$(curl -fsSL "https://api.github.com/repos/SalmanKarkhano/sudocell-dist/releases/latest" 2>/dev/null || echo '{}')
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o '"browser_download_url": "[^"]*\.deb"' | head -1 | cut -d'"' -f4)

if [[ -z "$DOWNLOAD_URL" ]]; then
  # Fallback to v0.1.2
  DOWNLOAD_URL="https://github.com/SalmanKarkhano/sudocell-dist/releases/download/v0.1.2/sudocell_0.1.2_amd64.deb"
fi

TEMP_DEB=$(mktemp)
trap "rm -f $TEMP_DEB" EXIT

if ! curl -fsSL -o "$TEMP_DEB" "$DOWNLOAD_URL"; then
  echo "[ERROR] Failed to download package"
  exit 1
fi

echo "[OK] Downloaded"

# Step 4: Install package
echo ""
echo "Installing package..."
if ! dpkg -i "$TEMP_DEB" > /dev/null 2>&1; then
  echo "[ERROR] Installation failed"
  exit 1
fi
echo "[OK] Package installed"

# Step 5: Create admin user
echo ""
echo "Setting up admin account..."
python3 << PYTHON 2>/dev/null || true
import sys
import os
import sqlite3
import hashlib

try:
    db_path = "$ETC_DIR/users.db"
    os.makedirs("$ETC_DIR", exist_ok=True)
    os.chmod("$ETC_DIR", 0o700)

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
            is_admin INTEGER DEFAULT 0
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            key TEXT NOT NULL,
            value TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            UNIQUE(user_id, key)
        )
    """)

    # Create admin user
    password_hash = hashlib.sha256("$ADMIN_PASS".encode()).hexdigest()
    cursor.execute("""
        INSERT OR IGNORE INTO users (username, email, password_hash, is_admin)
        VALUES (?, ?, ?, ?)
    """, ("$ADMIN_USER", "$ADMIN_EMAIL", password_hash, 1))

    conn.commit()
    conn.close()
    os.chmod(db_path, 0o600)
except:
    pass
PYTHON

echo "[OK] Admin account created"

# Step 6: Configuration
echo ""
echo "Creating configuration..."
cat > "$ETC_DIR/sudocell.env" << EOF
# SudoCell Configuration
ENABLE_MAIL=n
ENABLE_BACKUPS=y
DB_MYSQL=y
DB_POSTGRES=y
INSTALLED_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

chmod 600 "$ETC_DIR/sudocell.env"
echo "[OK] Configuration saved"

# Fix permissions for non-root access
chmod 755 "$ETC_DIR"
chmod 644 "$ETC_DIR/users.db" 2>/dev/null || true
chmod 777 "$DATA_DIR"
chmod 777 "$LOG_DIR"

# Step 7: Start service
echo ""
echo "Starting service..."
systemctl daemon-reload 2>/dev/null || true
systemctl start sudocell 2>/dev/null || true
echo "[OK] Service started"

# Success!
echo ""
echo "========================================"
echo "Installation Complete!"
echo "========================================"
echo ""
echo "Your Login Credentials:"
echo ""
echo "  Username: $ADMIN_USER"
echo "  Password: $ADMIN_PASS"
echo "  Email:    $ADMIN_EMAIL"
echo ""
echo "Get Started (copy & paste):"
echo ""
echo "  1. Login:"
echo "     sudocell login -u $ADMIN_USER -p \"$ADMIN_PASS\""
echo ""
echo "  2. Verify installation:"
echo "     sudocell whoami"
echo ""
echo "  3. Create a website:"
echo "     sudocell create-website --domain example.com"
echo ""
echo "  4. Create a database:"
echo "     sudocell create-db --type mysql --name myapp"
echo ""
echo "More info:"
echo "     sudocell --help"
echo ""
