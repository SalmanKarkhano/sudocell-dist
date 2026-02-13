# SudoCell Quick Reference Card

## 🚀 Installation

```bash
# One-liner (recommended)
bash <(curl -fsSL https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/install.sh)

# Or download first
curl -o install.sh https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/install.sh
sudo bash install.sh
```

---

## 👤 Authentication

```bash
# Login with credentials (generated during installation)
sudocell login -u USERNAME -p "PASSWORD"

# Check who you are
sudocell whoami

# Logout
sudocell logout
```

---

## 🌐 Website Management

```bash
# Create a new website
sudocell create-website --domain example.com

# List your websites
sudocell list-websites

# Delete a website
sudocell delete-website --domain example.com

# Enable/disable a website
sudocell enable-website --domain example.com
sudocell disable-website --domain example.com
```

---

## 🗄️ Database Management

```bash
# Create MySQL database
sudocell create-db --type mysql --name myapp_db

# Create PostgreSQL database
sudocell create-db --type postgres --name myapp_db

# List databases
sudocell list-databases

# Delete database
sudocell delete-db --name myapp_db
```

---

## 👥 User Management

```bash
# Create new user (requires admin login)
sudocell create-user --username john --email john@example.com

# Create admin user
sudocell create-user --username admin2 --email admin@example.com --is-admin

# List all users (admin only)
sudocell list-users

# Delete user (admin only)
sudocell delete-user --username john
```

---

## 📁 File Management

```bash
# Set up FTP/SFTP for user
sudocell setup-ftp --username john

# Change FTP password
sudocell change-ftp-password --username john

# Get FTP details
sudocell get-ftp-details --username john
```

---

## 📊 Status & Information

```bash
# View system status
sudocell status

# Check disk usage
sudocell usage

# View configuration
sudocell config

# View version
sudocell --version

# Get help
sudocell --help
sudocell create-website --help
```

---

## 🔧 Configuration Files

```bash
# Main configuration
sudo nano /etc/sudocell/sudocell.env

# View logs
sudo tail -f /var/log/sudocell/sudocell.log
sudo tail -f /var/log/sudocell/error.log

# Service control
sudo systemctl status sudocell
sudo systemctl start sudocell
sudo systemctl stop sudocell
sudo systemctl restart sudocell
```

---

## 🔐 Security

```bash
# Change admin password
sudocell change-password

# Change user password (admin only)
sudocell change-user-password --username john

# Reset admin access
sudo systemctl stop sudocell
sudo rm -f /etc/sudocell/users.db
sudo systemctl start sudocell
# Reinstall with: sudo bash install.sh
```

---

## 🔄 Updates & Maintenance

```bash
# Update SudoCell
sudo bash <(curl -fsSL https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/update.sh)

# Or manually
curl -o install.sh https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/install.sh
sudo bash install.sh

# Check for updates
sudocell check-updates
```

---

## 🗑️ Uninstall

```bash
# Full uninstall script
sudo bash <(curl -fsSL https://raw.githubusercontent.com/SalmanKarkhano/sudocell-dist/main/uninstall.sh)

# Or manually
sudo systemctl stop sudocell
sudo systemctl disable sudocell
sudo rm -rf /opt/sudocell /etc/sudocell /var/lib/sudocell /var/log/sudocell
sudo rm -f /usr/local/bin/sudocell /etc/systemd/system/sudocell.service
sudo systemctl daemon-reload
```

---

## 🆘 Troubleshooting

```bash
# View error logs
sudo journalctl -u sudocell -n 50

# Check service status
sudo systemctl status sudocell -l

# Restart service
sudo systemctl restart sudocell

# Fix broken installation
sudo apt --fix-broken install

# Verify Python is installed
python3 --version

# Check disk space
df -h
```

---

## 📞 Getting Help

```bash
# View comprehensive help
sudocell --help

# Help for specific command
sudocell create-website --help
sudocell create-db --help

# Report issues
https://github.com/SalmanKarkhano/sudocell-dist/issues

# View documentation
https://github.com/SalmanKarkhano/sudocell-dist
```

---

**Version**: 0.2.0 | **Updated**: February 2026

💡 **Tip**: Bookmark this page for quick reference!
