# 🚀 SudoCell Distribution

**Professional Hosting Control Panel** - One-click installation for modern web hosting management.

[![GitHub Release](https://img.shields.io/github/v/release/SalmanKarkhano/sudocell-dist)](https://github.com/SalmanKarkhano/sudocell-dist/releases)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/SalmanKarkhano/sudocell-dist?style=social)](https://github.com/SalmanKarkhano/sudocell-dist)

---

## ⚡ Quick Start

### Method 1: Piped Installation (Recommended - Most Compatible)

This is the traditional and most reliable method:

```bash
curl -fsSL https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/install.sh | sudo bash
```

### Method 2: One-Liner Installation (Alternative)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/install.sh)
```

### Method 3: Two-Step Installation

If piping doesn't work on your system:

```bash
# Step 1: Download the installer
curl -o /tmp/install.sh https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/install.sh

# Step 2: Run as root
sudo bash /tmp/install.sh
```

### Method 4: Direct .deb Installation

Install the package directly without running the full installer:

```bash
# Download the package
curl -o /tmp/sudocell_0.2.0_all.deb https://github.com/SalmanKarkhano/sudocell-dist/raw/main/sudocell_0.2.0_all.deb

# Install with dpkg
sudo dpkg -i /tmp/sudocell_0.2.0_all.deb

# Install dependencies if needed
sudo apt --fix-broken install
```

### Method 5: Using wget

If you prefer `wget`:

```bash
curl -fsSL https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/install.sh | bash
```

Or with sudo:

```bash
curl -fsSL https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/install.sh | sudo bash
```

---

## ✨ Features

- 🔐 **Secure Authentication** - bcrypt password hashing with PBKDF2 fallback
- 🗄️ **Database Management** - MySQL and PostgreSQL support
- 🌐 **Website Hosting** - Static and dynamic website deployment
- 📁 **File Management** - FTP/SFTP access for users
- 👥 **Multi-Tenant** - Isolated user environments
- 📊 **Resource Management** - Track usage and quotas
- ⚙️ **CLI Interface** - Full command-line control
- 🔄 **One-Click Updates** - Keep your system current

---

## 📋 System Requirements

### Supported Operating Systems
- **Debian 10+** (Buster or later)
- **Ubuntu 18.04+**
- **CentOS 7+**
- **RHEL 7+**
- **Fedora 30+**

### Minimum Specifications
- **CPU**: 1 core (2+ recommended)
- **RAM**: 512 MB (2 GB recommended)
- **Disk**: 2 GB free space
- **Network**: Internet connection for installation

### Dependencies (Auto-installed)
- Python 3.8+
- MySQL Client
- PostgreSQL Client
- OpenSSH Server
- VSFTPD (FTP Server)

---

## 🎯 What Gets Installed

The installer sets up:

```
├── /opt/sudocell/              # Application directory
│   └── sudocell/               # Python package with 7 modules
│       ├── auth/               # Authentication & sessions
│       ├── cli/                # Command-line interface
│       ├── core/               # Core engine
│       ├── database/           # Database management
│       ├── ftp/                # FTP/SFTP handling
│       ├── utils/              # Utilities
│       └── websites/           # Website management
├── /etc/sudocell/              # Configuration directory
│   ├── sudocell.env            # Environment configuration
│   ├── sudocell.conf           # Main configuration
│   └── users.db                # User database (SQLite)
├── /var/lib/sudocell/          # Data directory
├── /var/log/sudocell/          # Log directory
└── /usr/local/bin/sudocell     # CLI entry point
```

---

## 🔧 Basic Usage

### Login

```bash
sudocell login -u admin1234 -p "your_password"
```

### Create a Website

```bash
sudocell create-website --domain example.com
```

### Create a Database

```bash
# MySQL
sudocell create-db --type mysql --name myapp_db

# PostgreSQL
sudocell create-db --type postgres --name myapp_db
```

### Check Your Status

```bash
sudocell whoami
```

### View All Commands

```bash
sudocell --help
```

---

## 📚 Documentation

### Getting Started
- See the welcome message after installation
- Your credentials are displayed at the end of setup
- Admin credentials are securely generated

### Command Reference
Comprehensive CLI documentation available via:
```bash
sudocell --help
sudocell create-website --help
sudocell create-db --help
```

### Configuration

Edit `/etc/sudocell/sudocell.env` to customize:
```bash
# Enable/disable features
ENABLE_MAIL=n
ENABLE_BACKUPS=y
DB_MYSQL=y
DB_POSTGRES=y
ENABLE_FTP=y
```

---

## 🔐 Security Features

✅ **Password Security**
- bcrypt hashing (12 rounds) with PBKDF2 fallback
- Secure random credential generation
- Password never exposed in process lists

✅ **File Permissions**
- Sensitive files: 600 (owner read/write only)
- Shared directories: 750 (group readable)
- Config directories: 700 (owner only)

✅ **Multi-Tenant Isolation**
- Per-user database connections
- Isolated file system access
- Session-based authentication

---

## 🛠️ Troubleshooting

### Installation Fails

```bash
# Check system logs
sudo journalctl -u sudocell -n 50

# Verify dependencies
apt install python3-pip mysql-client postgresql-client vsftpd openssh-server

# Fix broken installation
sudo apt --fix-broken install
```

### Lost Admin Password?

```bash
# Create a new admin user via CLI after login with an existing account
sudocell create-user --username newadmin --email admin@example.com --is-admin
```

### Service Won't Start

```bash
# Check service status
sudo systemctl status sudocell

# View detailed logs
sudo tail -f /var/log/sudocell/*.log

# Restart service
sudo systemctl restart sudocell
```

---

## 📦 What's Included in v0.2.0

### ✨ New Features
- Modular architecture with 7 clean Python modules
- Enhanced bcrypt-based password security
- Improved FTP/SFTP integration
- Better error handling and logging
- Professional installers for all platforms

### 🐛 Bug Fixes
- Fixed critical install.sh syntax errors
- Resolved race conditions in session management
- Fixed database permission vulnerabilities
- Enhanced error messages and rollback support

### 📈 Improvements
- Cleaner code organization
- Better backward compatibility
- Improved installation reliability
- Enhanced security defaults

---

## 🔄 Updating

### Check Current Version

```bash
sudocell --version
```

### Auto-Update

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/update.sh)
```

### Manual Update

```bash
# Download latest installer
curl -o install.sh https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/install.sh

# Run update
sudo bash install.sh
```

---

## 🗑️ Uninstallation

To completely remove SudoCell:

```bash
sudo bash <(curl -fsSL https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/uninstall.sh)
```

Or manually:

```bash
sudo systemctl stop sudocell
sudo systemctl disable sudocell
sudo rm -rf /opt/sudocell /etc/sudocell /var/lib/sudocell /var/log/sudocell
sudo rm -f /usr/local/bin/sudocell /etc/systemd/system/sudocell.service
sudo systemctl daemon-reload
```

---

## 🐛 Reporting Issues

Found a bug? Help us improve:

1. Check [existing issues](https://github.com/SalmanKarkhano/sudocell-dist/issues)
2. Provide system info: `uname -a`, `lsb_release -a`
3. Include error messages and logs
4. [Create a new issue](https://github.com/SalmanKarkhano/sudocell-dist/issues/new)

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file

---

## 🔗 Links

- **Main Repository**: https://github.com/SalmanKarkhano/Sudocell
- **Distribution Repo**: https://github.com/SalmanKarkhano/sudocell-dist
- **Issues & Support**: https://github.com/SalmanKarkhano/sudocell-dist/issues
- **GitHub**: [@SalmanKarkhano](https://github.com/SalmanKarkhano)

---

## ⭐ Support

If SudoCell helps you, please consider:
- ⭐ Starring the repo
- 🐛 Reporting bugs
- 💡 Suggesting features
- 📢 Sharing with others

---

**Made with ❤️ for the hosting community**

Version 0.2.0 | Last Updated: February 2026
