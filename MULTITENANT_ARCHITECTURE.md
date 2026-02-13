# SudoCell v0.2.0 - Multi-Tenant Architecture

## Overview

SudoCell v0.2.0 implements a professional multi-tenant hosting control panel architecture similar to cPanel and Plesk. Each user has complete file isolation, server access, and resource management within their own environment.

## Architecture

### 1. User Management

#### System Users
- Each SudoCell account automatically creates a **Linux system user**
- System user cannot login via shell (`/usr/sbin/nologin`)
- Home directory: `/home/{username}`
- Automatic home directory structure creation

#### User Types
- **Admin**: Can create/delete users, manage system settings
- **Reseller/User**: Regular accounts with their own web hosting space

#### User Commands
```bash
# Create new user account
sudocell create-user --username alice --email alice@example.com

# List all users (admin only)
sudocell list-users

# Delete user (admin only)
sudocell delete-user --username alice

# Change password
sudocell change-password --username alice
```

### 2. File Structure & Isolation

#### Directory Layout
```
/home/alice/
├── public_html/               # Web root
│   ├── example.com/
│   │   ├── public/           # Website files
│   │   ├── logs/             # Access/error logs
│   │   ├── backups/          # Backups
│   │   └── .sudocell.json    # Metadata
│   └── another-domain.com/
├── .ssh/                      # SSH keys
└── .bashrc                    # User profile
```

#### Permissions
- **Home directory**: `755` (owned by user)
- **public_html**: `755` (owned by user)
- **Domain folders**: `755` (owned by user)
- **Website files**: `644` (user can edit)

#### Access Control
- Users **only** have permissions to their own `/home/{username}/` directory
- Linux kernel enforces file isolation at OS level
- Root/Admin can access all user files for management

### 3. Website Management

#### Creating a Website
```bash
# User logs in
sudocell login -u alice -p password

# Create website
sudocell create-website --domain example.com

# Website is created at:
# /home/alice/public_html/example.com/
```

#### Website Structure
```
/home/alice/public_html/example.com/
├── public/              # Document root served by web server
│   ├── index.html
│   └── ...
├── logs/                # Per-domain logging
│   ├── access.log
│   └── error.log
├── backups/             # Backup storage
└── .sudocell.json       # Metadata
```

#### Database per User
- Each user owns their MySQL/PostgreSQL databases
- Database credentials unique to each user
- Users can only access their own databases

### 4. FTP/SFTP Access

#### SFTP (Recommended)
Users connect via SFTP using their SudoCell credentials:
```bash
sftp alice@hosting-server.com
cd public_html/example.com/public
put index.html
```

#### FTP (if enabled)
VSFTPD authenticates against system users:
```bash
ftp alice@hosting-server.com
# Uses alice's system password
cd public_html
put website.zip
```

#### Access Restrictions
- Users can only access their home directory
- Cannot browse other users' files
- SSH/SFTP-only shell prevents command execution
- Isolated chroot environment

### 5. Database Management

#### User Database (/etc/sudocell/users.db)
```
users table:
- id
- username (unique)
- email
- password_hash (SHA-256)
- is_admin flag
- system_user flag
- created_at

websites table:
- domain
- path
- owner (user_id)
- enabled flag

websites_domains table:
- domain -> user mapping
```

#### Per-User Access Control
- MySQL/PostgreSQL credentials stored in database
- Each user granted access to only their databases
- Passwords encrypted in storage

### 6. Multi-Tenant Isolation

#### Security Layers

1. **Filesystem**
   - Linux user/group permissions
   - Home directory isolation

2. **Database**
   - SQL queries filtered by user_id
   - No access to other users' data

3. **Application**
   - CLI commands check user context
   - Website creator uses current user

4. **Network**
   - SFTP connections authenticated per user
   - VSFTPD restricts to home directory

### 7. Admin Panel Features

#### User Management
```bash
# Create user
sudocell create-user \
  --username john \
  --email john@company.com

# List users
sudocell list-users

# Delete user
sudocell delete-user --username john
```

#### Website Management
```bash
# Create website (as user)
sudocell create-website --domain mysite.com

# Get user's websites
sudocell list-user-sites --username alice
```

#### Database Management
```bash
# Create database (as user)
sudocell create-db --type mysql --name wordpress

# Database credentials isolated per user
```

### 8. Installation Changes (v0.2.0)

#### New Dependencies
- `vsftpd` (FTP daemon)
- `openssh-server` (SFTP)

#### Automatic Setup
1. Creates SQLite database with new schema
2. Configures VSFTPD authentication
3. Sets up SSH/SFTP subsystem
4. Creates admin account (no system user)
5. Creates home directory skel for future users

#### Database Schema Additions
- `users.system_user` - flag for system user creation
- `websites` table - domain ownership tracking
- PAM integration for FTP

### 9. File Access Workflow

```
User Login
   ↓
[Session Manager] saves /var/lib/sudocell/current_user.json
   ↓
User runs command (e.g., create-website)
   ↓
CLI reads current_user.json
   ↓
Website creator uses username from session
   ↓
Website created at /home/{username}/public_html/domain/
   ↓
Files owned by {username}:{username}
   ↓
Database registers ownership (websites table)
  ↓
FTP/SFTP grants access to /home/{username}/
```

### 10. Production Deployment

#### Recommended Setup
```bash
# 1. Install SudoCell
curl -fsSL https://raw.githubusercontent.com/.../install.sh | sudo bash

# 2. Login as admin
sudocell login -u admin1234 -p <generated-password>

# 3. Create reseller accounts
sudocell create-user --username reseller1 --email reseller@company.com
sudocell create-user --username reseller2 --email reseller2@company.com

# 4. Users login and create websites
# Each user connects via SFTP with their password
```

#### Typical User Workflow
```bash
# User logs in locally
sudocell login -u alice -p alice_password

# Creates 3 websites
sudocell create-website --domain site1.com
sudocell create-website --domain site2.com
sudocell create-website --domain site3.com

# Uploads via SFTP
sftp alice@hosting.com
  put index.html public_html/site1.com/public/
  put style.css public_html/site1.com/public/
  
# Creates databases
sudocell create-db --type mysql --name site1_db
sudocell create-db --type mysql --name site2_db

# Result:
# /home/alice/public_html/ - fully owned by alice
# Databases - only alice can access
# FTP/SFTP - alice can only see her files
```

### 11. Comparison: v0.1.2 vs v0.2.0

| Feature | v0.1.2 | v0.2.0 |
|---------|--------|--------|
| User Accounts | Database only | System + Database |
| File Storage | Random directory | `/home/{user}/public_html/` |
| File Isolation | None | OS-level isolation |
| FTP/SFTP | Not supported | Full multi-user support |
| Website Owner | None | User-bound in database |
| Admin Features | Create database/website | Full user management |
| Multi-tenant | No | Yes, like cPanel |
| Website Path | `./websites/` | `/home/alice/public_html/` |
| Access Control | None | File permissions + SQL filters |

### 12. Migration from v0.1.2 to v0.2.0

For existing v0.1.2 installations upgrading to v0.2.0:

```bash
# 1. Backup current data
sudo cp -r /etc/sudocell /etc/sudocell.backup

# 2. Run updater
sudocell update

# 3. Migration script will:
# - Create system users for each database user
# - Move website files to /home/{user}/public_html/
# - Update database with file paths
# - Reset permissions
```

### 13. Troubleshooting

#### User can't write files via SFTP
```bash
# Check permissions
sudo ls -la /home/username/public_html/

# Fix ownership
sudo chown -R username:username /home/username/public_html/

# Fix permissions
sudo chmod -R 755 /home/username/public_html/
```

#### FTP not working
```bash
# Check VSFTPD
sudo systemctl status vsftpd

# Check PAM configuration
sudo cat /etc/pam.d/vsftpd

# Test system user
id alice  # Should work
sudo su - alice  # Should fail (nologin shell)
```

#### Website not accessible
```bash
# Check web server configuration
sudo nginx -t

# Check file ownership
sudo ls -la /home/alice/public_html/example.com/public/

# Check logs
sudo tail -f /home/alice/public_html/example.com/logs/error.log
```

## Version Information
- **Version**: 0.2.0
- **Release Type**: Production - Multi-Tenant Architecture
- **Target**: Professional hosting providers
- **Comparison**: cPanel-like functionality
