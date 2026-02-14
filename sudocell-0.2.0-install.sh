#!/usr/bin/env bash
# SudoCell - One-Click Installer for End Users
# Super simple, fully automated installation
# 
# For end users: Just run this - it does everything!
# curl -fsSL https://sudocell.io/install.sh | sudo bash
# 
# Or locally: sudo bash install-simple.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/sudocell"
CONFIG_DIR="/etc/sudocell"
DATA_DIR="/var/lib/sudocell"
LOG_DIR="/var/log/sudocell"
SERVICE_USER="sudocell"
SUDOCELL_VERSION="0.2.0"
SUDOCELL_DIST_URL="${SUDOCELL_DIST_URL:-https://example.com}"
SUDOCELL_BINARY_URL="${SUDOCELL_BINARY_URL:-}"

# ============================================================================
# Utility Functions
# ============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# ============================================================================
# Checks
# ============================================================================

check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        print_error "This installer must be run as root"
        echo "Usage: sudo bash $0"
        exit 1
    fi
}

check_os() {
    if ! command -v apt-get &> /dev/null && ! command -v yum &> /dev/null; then
        print_error "Unsupported OS. Requires Ubuntu/Debian or CentOS/RHEL"
        exit 1
    fi
}

detect_arch() {
    local raw_arch
    raw_arch=$(uname -m)
    case "${raw_arch}" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "aarch64"
            ;;
        *)
            print_error "Unsupported architecture: ${raw_arch}"
            exit 1
            ;;
    esac
}

check_existing() {
    if [[ -d "$INSTALL_DIR" ]]; then
        print_error "SudoCell is already installed at $INSTALL_DIR"
        echo ""
        read -p "Do you want to reinstall? (y/n): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled"
            exit 0
        fi
        print_info "Removing old installation..."
        systemctl stop sudocell 2>/dev/null || true
        rm -rf "$INSTALL_DIR" "$DATA_DIR" "$LOG_DIR" 2>/dev/null || true
    fi
}

# ============================================================================
# Installation Steps
# ============================================================================

create_directories() {
    print_info "Creating directories..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$DATA_DIR"
    mkdir -p "$LOG_DIR"
    print_success "Directories created"
}

create_service_user() {
    print_info "Creating service user..."
    
    if id "$SERVICE_USER" &>/dev/null; then
        print_success "Service user '$SERVICE_USER' already exists"
    else
        useradd -r -s /usr/sbin/nologin -d "$DATA_DIR" "$SERVICE_USER"
        print_success "Service user '$SERVICE_USER' created"
    fi
}

install_dependencies() {
    print_info "Installing dependencies..."
    
    if command -v apt-get &> /dev/null; then
        apt-get update -qq
        apt-get install -y \
            curl \
            wget \
            nginx \
            sqlite3 \
            2>&1 | grep -v "^Reading\|^Building\|^Setting up" || true
    else
        yum install -y \
            curl \
            wget \
            nginx \
            sqlite \
            2>&1 | grep -v "^Loaded\|^Loading\|^Dependencies" || true
    fi
    
    print_success "Dependencies installed"
}

download_sudocell() {
    print_info "Downloading SudoCell binary..."

    local arch
    local binary_name
    local url

    arch=$(detect_arch)
    binary_name="sudocell-${SUDOCELL_VERSION}-linux-${arch}"
    url="${SUDOCELL_BINARY_URL}"

    if [[ -z "${url}" ]]; then
        url="${SUDOCELL_DIST_URL}/${binary_name}"
    fi

    cd /tmp
    if command -v curl &> /dev/null; then
        curl -fsSL "${url}" -o "${INSTALL_DIR}/sudocell"
    elif command -v wget &> /dev/null; then
        wget -qO "${INSTALL_DIR}/sudocell" "${url}"
    else
        print_error "curl or wget is required to download the binary"
        exit 1
    fi

    chmod +x "${INSTALL_DIR}/sudocell"

    print_success "SudoCell binary downloaded"
}

setup_permissions() {
    print_info "Setting up permissions..."
    
    chown -R root:root "$INSTALL_DIR"
    chown -R "$SERVICE_USER:$SERVICE_USER" "$CONFIG_DIR" "$DATA_DIR" "$LOG_DIR"
    
    chmod 755 "$INSTALL_DIR"
    chmod 700 "$CONFIG_DIR" "$DATA_DIR" "$LOG_DIR"
    
    # Allow sudocell user to run required commands
    if [[ ! -f /etc/sudoers.d/sudocell ]]; then
        cat > /etc/sudoers.d/sudocell <<EOF
sudocell ALL=(ALL) NOPASSWD: /usr/sbin/useradd
sudocell ALL=(ALL) NOPASSWD: /usr/sbin/userdel
sudocell ALL=(ALL) NOPASSWD: /usr/sbin/usermod
sudocell ALL=(ALL) NOPASSWD: /bin/passwd
sudocell ALL=(ALL) NOPASSWD: /usr/bin/chown
EOF
        chmod 440 /etc/sudoers.d/sudocell
    fi
    
    print_success "Permissions configured"
}

setup_database() {
    print_info "Initializing database..."
    
    # Create database with proper permissions
    touch "$DATA_DIR/users.db"
    chown "$SERVICE_USER:$SERVICE_USER" "$DATA_DIR/users.db"
    chmod 600 "$DATA_DIR/users.db"
    
    print_success "Database initialized"
}

create_systemd_service() {
    print_info "Creating systemd service..."
    
    cat > /etc/systemd/system/sudocell.service <<'EOF'
[Unit]
Description=SudoCell Hosting Control Panel
After=network.target

[Service]
Type=simple
User=sudocell
WorkingDirectory=/opt/sudocell
ExecStart=/opt/sudocell/sudocell
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable sudocell
    
    print_success "Systemd service created"
}

generate_credentials() {
    print_info "Generating admin credentials..."
    
    ADMIN_USER="admin"
    ADMIN_PASS=$(openssl rand -base64 12)
    ADMIN_EMAIL="admin@sudocell.local"
    
    cat > "$CONFIG_DIR/admin-credentials.txt" <<EOF
╔════════════════════════════════════════════════════════════╗
║              SudoCell Admin Credentials                    ║
║         SAVE THESE - You cannot recover them!              ║
╚════════════════════════════════════════════════════════════╝

Username: $ADMIN_USER
Password: $ADMIN_PASS
Email:    $ADMIN_EMAIL

Keep this file secure:
  /etc/sudocell/admin-credentials.txt

Change password after first login:
  sudo sudocell user change-password $ADMIN_USER

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Default access:
  Web UI: http://localhost:8080/admin
  CLI:    sudocell

First steps:
  1. Change admin password
  2. Configure your domains
  3. Create user accounts
  4. Set up email (Postfix/Dovecot)
  5. Set up databases (MySQL/PostgreSQL)

Documentation: https://github.com/SalmanKarkhano/Sudocell/wiki
EOF

    chmod 600 "$CONFIG_DIR/admin-credentials.txt"
    chown "$SERVICE_USER:$SERVICE_USER" "$CONFIG_DIR/admin-credentials.txt"
    
    print_success "Admin credentials saved to $CONFIG_DIR/admin-credentials.txt"
}

setup_cli() {
    print_info "Setting up CLI..."
    
    ln -sf "$INSTALL_DIR/sudocell" /usr/local/bin/sudocell 2>/dev/null || true
    chmod +x /usr/local/bin/sudocell 2>/dev/null || true
    
    print_success "CLI available as 'sudocell' command"
}

# ============================================================================
# Post-Installation
# ============================================================================

post_install() {
    print_header "Installation Complete! ✓"
    
    echo -e "${GREEN}SudoCell has been successfully installed!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. View admin credentials:"
    echo "     cat /etc/sudocell/admin-credentials.txt"
    echo ""
    echo "  2. Start the service:"
    echo "     systemctl start sudocell"
    echo ""
    echo "  3. Check status:"
    echo "     systemctl status sudocell"
    echo ""
    echo "  4. View logs:"
    echo "     journalctl -u sudocell -f"
    echo ""
    echo "Documentation:"
    echo "  https://github.com/SalmanKarkhano/Sudocell"
    echo ""
    echo "Directories:"
    echo "  Install:  $INSTALL_DIR"
    echo "  Config:   $CONFIG_DIR"
    echo "  Data:     $DATA_DIR"
    echo "  Logs:     $LOG_DIR"
    echo ""
    
    # Try to start the service
    print_info "Starting SudoCell service..."
    if systemctl start sudocell; then
        print_success "Service started"
        echo ""
        echo "You can now access SudoCell!"
    else
        print_error "Failed to start service. Run: systemctl start sudocell"
    fi
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
    print_header "SudoCell One-Click Installer"
    
    print_info "Performing pre-installation checks..."
    check_root
    check_os
    check_existing
    print_success "All pre-installation checks passed"
    echo ""
    
    print_header "Installing SudoCell"
    
    create_directories
    create_service_user
    install_dependencies
    download_sudocell
    setup_permissions
    setup_database
    create_systemd_service
    setup_cli
    generate_credentials
    
    post_install
}

# ============================================================================
# Run Installation
# ============================================================================

# Trap errors
trap 'print_error "Installation failed!"; exit 1' ERR

# Start installation
main

exit 0
