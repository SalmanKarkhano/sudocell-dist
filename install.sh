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

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🚀 SudoCell One-Click Installer v0.1.2  ║${NC}"
echo -e "${BLUE}║     Hosting Control Panel              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if already installed
if [[ -d "$INSTALL_DIR" ]]; then
  echo -e "${YELLOW}⚠️  SudoCell is already installed.${NC}"
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

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  📦 Installing SudoCell...${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Step 1: Create directories
echo -e "${BLUE}📁 Creating directories...${NC}"
mkdir -p "$INSTALL_DIR/lib"
mkdir -p "$ETC_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"
chmod 700 "$ETC_DIR"
chmod 700 "$DATA_DIR"
chmod 700 "$LOG_DIR"
echo -e "${GREEN}✓${NC} Directories created"

# Step 2: Install system dependencies
echo ""
echo -e "${BLUE}📚 Installing system dependencies...${NC}"
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -qq > /dev/null 2>&1 || true
  apt-get install -y -qq python3 mysql-client postgresql-client > /dev/null 2>&1 || true
  echo -e "${GREEN}✓${NC} Dependencies installed (Debian/Ubuntu)"
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y -q python3 mysql postgresql > /dev/null 2>&1 || true
  echo -e "${GREEN}✓${NC} Dependencies installed (Fedora/RHEL)"
elif command -v yum >/dev/null 2>&1; then
  yum install -y -q python3 mysql postgresql > /dev/null 2>&1 || true
  echo -e "${GREEN}✓${NC} Dependencies installed (CentOS/RHEL)"
else
  echo -e "${YELLOW}⚠️  No supported package manager found${NC}"
fi

# Step 3: Download latest release
echo ""
echo -e "${BLUE}⬇️  Downloading latest release...${NC}"

RELEASE_INFO=$(curl -fsSL "https://api.github.com/repos/SalmanKarkhano/sudocell-dist/releases/latest" 2>/dev/null || echo '{}')
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o '"browser_download_url": "[^"]*\.deb"' | head -1 | cut -d'"' -f4)

if [[ -z "$DOWNLOAD_URL" ]]; then
  # Fallback to v0.1.2
  DOWNLOAD_URL="https://github.com/SalmanKarkhano/sudocell-dist/releases/download/v0.1.2/sudocell_0.1.2_amd64.deb"
fi

TEMP_DEB=$(mktemp)
trap "rm -f $TEMP_DEB" EXIT

if ! curl -fsSL -o "$TEMP_DEB" "$DOWNLOAD_URL"; then
  echo -e "${RED}❌ Failed to download package${NC}"
  exit 1
fi

echo -e "${GREEN}✓${NC} Downloaded"

# Step 4: Install package
echo ""
echo -e "${BLUE}📦 Installing package...${NC}"
if ! dpkg -i "$TEMP_DEB" > /dev/null 2>&1; then
  echo -e "${RED}❌ Installation failed${NC}"
  exit 1
fi
echo -e "${GREEN}✓${NC} Package installed"

# Step 5: Create admin user
echo ""
echo -e "${BLUE}🔐 Setting up admin account...${NC}"
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

echo -e "${GREEN}✓${NC} Admin account created"

# Step 6: Configuration
echo ""
echo -e "${BLUE}⚙️  Creating configuration...${NC}"
cat > "$ETC_DIR/sudocell.env" << EOF
# SudoCell Configuration
ENABLE_MAIL=n
ENABLE_BACKUPS=y
DB_MYSQL=y
DB_POSTGRES=y
INSTALLED_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

chmod 600 "$ETC_DIR/sudocell.env"
echo -e "${GREEN}✓${NC} Configuration saved

# Fix permissions for non-root access
chmod 755 "$ETC_DIR"
chmod 644 "$ETC_DIR/users.db" 2>/dev/null || true
chmod 777 "$DATA_DIR"
chmod 777 "$LOG_DIR"

# Step 7: Start service
echo ""
echo -e "${BLUE}🚀 Starting service...${NC}"
systemctl daemon-reload 2>/dev/null || true
systemctl start sudocell 2>/dev/null || true
echo -e "${GREEN}✓${NC} Service started"

# Success!
echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Installation Complete!${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}📋 Your Login Credentials:${NC}"
echo ""
echo -e "  ${BLUE}Username:${NC} ${GREEN}$ADMIN_USER${NC}"
echo -e "  ${BLUE}Password:${NC} ${GREEN}$ADMIN_PASS${NC}"
echo -e "  ${BLUE}Email:${NC}    ${GREEN}$ADMIN_EMAIL${NC}"
echo ""
echo -e "${YELLOW}🚀 Get Started (copy & paste):${NC}"
echo ""
echo -e "  ${BLUE}1. Login:${NC}"
echo "     sudocell login -u $ADMIN_USER -p '$ADMIN_PASS'"
echo ""
echo -e "  ${BLUE}2. Verify installation:${NC}"
echo "     sudocell whoami"
echo ""
echo -e "  ${BLUE}3. Create a website:${NC}"
echo "     sudocell create-website --domain example.com"
echo ""
echo -e "  ${BLUE}4. Create a database:${NC}"
echo "     sudocell create-db --type mysql --name myapp"
echo ""
echo -e "${YELLOW}📖 More info:${NC}"
echo "     sudocell --help"
echo ""
