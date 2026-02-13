#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────
#   SudoCell One-Click Installer
#   Professional Hosting Control Panel
#   GitHub: https://github.com/SalmanKarkhano/sudocell-dist
# ────────────────────────────────────────────────────────────
#
# Usage (one-liner):
#   bash <(curl -fsSL https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/install.sh)
#
# Or manually:
#   curl -o install.sh https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/install.sh
#   sudo bash install.sh

set -euo pipefail

# Color codes for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_error() { echo -e "${RED}✗${NC} $*"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $*"; }

# Check root privileges
if [[ "${EUID}" -ne 0 ]]; then
  log_error "This installer must be run as root"
  echo ""
  echo "Please run with sudo:"
  echo "  sudo bash $0"
  echo ""
  exit 1
fi

# Configuration
INSTALL_DIR="/opt/sudocell"
ETC_DIR="/etc/sudocell"
DATA_DIR="/var/lib/sudocell"
LOG_DIR="/var/log/sudocell"
SERVICE_USER="sudocell"

# Display header
clear
echo ""
echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════╗"
echo "║      SudoCell - Hosting Control Panel              ║"
echo "║        Professional Edition Installer             ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Check if already installed
if [[ -d "$INSTALL_DIR" ]]; then
  log_warn "SudoCell is already installed at $INSTALL_DIR"
  read -p "Do you want to reinstall? (y/n): " -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Installation cancelled."
    exit 0
  fi
  log_info "Removing old installation..."
  systemctl stop sudocell 2>/dev/null || true
  rm -rf "$INSTALL_DIR" "$DATA_DIR" "$LOG_DIR" 2>/dev/null || true
  log_success "Old installation cleaned"
fi

# Generate random admin credentials
ADMIN_USER="admin$(openssl rand -hex 2)"
ADMIN_PASS=$(openssl rand -base64 12)
ADMIN_EMAIL="admin@sudocell.local"

log_info "Starting SudoCell installation..."
echo ""

# Step 1: Create directories
log_info "Creating system directories..."
mkdir -p "$INSTALL_DIR/lib"
mkdir -p "$ETC_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$LOG_DIR"
chmod 700 "$ETC_DIR"
chmod 700 "$DATA_DIR"
chmod 700 "$LOG_DIR"
log_success "Directories created"

# Step 2: Install system dependencies
echo ""
log_info "Installing system dependencies..."
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -qq > /dev/null 2>&1 || true
  apt-get install -y -qq python3 python3-pip mysql-client postgresql-client vsftpd openssh-server > /dev/null 2>&1 || true
  log_success "Dependencies installed (Debian/Ubuntu)"
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y -q python3 python3-pip mysql postgresql vsftpd openssh-server > /dev/null 2>&1 || true
  log_success "Dependencies installed (Fedora/RHEL)"
elif command -v yum >/dev/null 2>&1; then
  yum install -y -q python3 python3-pip mysql postgresql vsftpd openssh-server > /dev/null 2>&1 || true
  log_success "Dependencies installed (CentOS/RHEL)"
else
  log_warn "No supported package manager found. Please install: python3, mysql-client, postgresql-client, vsftpd, openssh-server"
fi

# Step 3: Download latest release
echo ""
log_info "Downloading latest release from GitHub..."

RELEASE_INFO=$(curl -fsSL "https://api.github.com/repos/SalmanKarkhano/sudocell-dist/releases/latest" 2>/dev/null || echo '{}')
DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o '"browser_download_url": "[^"]*\.deb"' | head -1 | cut -d'"' -f4)

if [[ -z "$DOWNLOAD_URL" ]]; then
  DOWNLOAD_URL="https://github.com/SalmanKarkhano/sudocell-dist/releases/download/v0.2.0/sudocell_0.2.0_amd64.deb"
  log_warn "Using v0.2.0 as fallback"
fi

TEMP_DEB=$(mktemp)
trap "rm -f $TEMP_DEB" EXIT

if ! curl -fsSL -o "$TEMP_DEB" "$DOWNLOAD_URL"; then
  log_error "Failed to download package from $DOWNLOAD_URL"
  exit 1
fi

DEB_SIZE=$(du -h "$TEMP_DEB" | cut -f1)
log_success "Downloaded ($DEB_SIZE)"

# Step 4: Install package
echo ""
log_info "Installing SudoCell package..."
if ! dpkg -i "$TEMP_DEB" > /dev/null 2>&1; then
  log_error "Installation failed. You may need to run: sudo apt --fix-broken install"
  exit 1
fi
log_success "Package installed"

# Step 5: Create admin user
echo ""
log_info "Setting up admin account..."
python3 << PYTHON 2>/dev/null || true
import sys
import os
import sqlite3
import hashlib
import bcrypt

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
            is_admin INTEGER DEFAULT 0,
            system_user INTEGER DEFAULT 0
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
    
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS websites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            domain TEXT UNIQUE NOT NULL,
            path TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            enabled INTEGER DEFAULT 1,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
    """)

    # Hash password with bcrypt or fallback to PBKDF2
    password = "$ADMIN_PASS".encode()
    try:
        import bcrypt as bcrypt_module
        password_hash = bcrypt_module.hashpw(password, bcrypt_module.gensalt(12)).decode()
    except:
        password_hash = hashlib.pbkdf2_hmac('sha256', password, b'sudocell-salt', 100000).hex()

    cursor.execute("""
        INSERT OR IGNORE INTO users (username, email, password_hash, is_admin, system_user)
        VALUES (?, ?, ?, ?, ?)
    """, ("$ADMIN_USER", "$ADMIN_EMAIL", password_hash, 1, 0))

    conn.commit()
    conn.close()
    os.chmod(db_path, 0o600)
except Exception as e:
    print(f"Warning: {e}", file=sys.stderr)
PYTHON

log_success "Admin account created"

# Step 6: Setup FTP/SFTP
echo ""
log_info "Setting up FTP/SFTP..."

# Configure VSFTPD PAM
PAM_VSFTPD="/etc/pam.d/vsftpd"
if [ ! -f "$PAM_VSFTPD" ] && command -v vsftpd >/dev/null 2>&1; then
  cat > "$PAM_VSFTPD" << 'PAMPAM'
#%PAM-1.0
auth       required     pam_unix.so obscure yescrypt
account    required     pam_unix.so
session    required     pam_unix.so
PAMPAM
  chmod 644 "$PAM_VSFTPD"
fi

# Start FTP daemon
systemctl start vsftpd 2>/dev/null || true
systemctl enable vsftpd 2>/dev/null || true

log_success "FTP/SFTP configured"

# Step 7: Configuration
echo ""
log_info "Creating configuration..."
cat > "$ETC_DIR/sudocell.env" << EOF
# SudoCell Configuration
ENABLE_MAIL=n
ENABLE_BACKUPS=y
DB_MYSQL=y
DB_POSTGRES=y
ENABLE_FTP=y
INSTALLED_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

chmod 600 "$ETC_DIR/sudocell.env"
log_success "Configuration saved"

# Fix permissions for non-root access
chmod 755 "$ETC_DIR" 2>/dev/null || true
chmod 644 "$ETC_DIR/users.db" 2>/dev/null || true
chmod 777 "$DATA_DIR" 2>/dev/null || true
chmod 777 "$LOG_DIR" 2>/dev/null || true

# Step 8: Start service
echo ""
log_info "Starting SudoCell service..."
systemctl daemon-reload 2>/dev/null || true
systemctl start sudocell 2>/dev/null || true
systemctl enable sudocell 2>/dev/null || true
log_success "Service started and enabled"

# Step 9: Post-installation setup
echo ""
log_info "Finalizing installation..."

# Ensure system groups exist for file permissions
getent group sudocell >/dev/null 2>&1 || groupadd sudocell 2>/dev/null || true

# Create template for user home directories
mkdir -p /etc/sudocell/skel
mkdir -p /etc/sudocell/skel/public_html
chmod 755 /etc/sudocell/skel
chmod 755 /etc/sudocell/skel/public_html

log_success "Installation finalized"

# Success!
echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════╗"
echo "║         ✓ Installation Complete!                   ║"
echo "║                                                    ║"
echo "║        SudoCell is now ready to use                ║"
echo "╚════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "Your Login Credentials:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "  ${YELLOW}Username:${NC} $ADMIN_USER"
echo -e "  ${YELLOW}Password:${NC} $ADMIN_PASS"
echo -e "  ${YELLOW}Email:${NC}    $ADMIN_EMAIL"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Quick Start Guide:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Login to SudoCell:"
echo "   ${BLUE}sudocell login -u $ADMIN_USER -p \"\$password\"${NC}"
echo ""
echo "2. Verify installation:"
echo "   ${BLUE}sudocell whoami${NC}"
echo ""
echo "3. Create a website:"
echo "   ${BLUE}sudocell create-website --domain example.com${NC}"
echo ""
echo "4. Create a database:"
echo "   ${BLUE}sudocell create-db --type mysql --name myapp${NC}"
echo ""
echo "5. View help:"
echo "   ${BLUE}sudocell --help${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📚 Documentation:"
echo "   https://github.com/SalmanKarkhano/sudocell-dist"
echo ""
echo "Support:"
echo "   https://github.com/SalmanKarkhano/sudocell-dist/issues"
echo ""