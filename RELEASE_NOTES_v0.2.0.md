# SudoCell v0.2.0 - Release Notes

## Release Date
February 13, 2026

## Version
**v0.2.0 - Professional Multi-Tenant Architecture**

## Overview

SudoCell v0.2.0 is a major architectural upgrade implementing professional multi-tenant hosting control panel functionality similar to cPanel and Plesk. This release provides complete file isolation, proper user management, and FTP/SFTP access control.

## Major Features

### 1. Multi-Tenant Architecture ✨
- **Per-User Home Directories**: Each user gets `/home/{username}/public_html/`
- **OS-Level Isolation**: Linux user/group permissions enforce access control
- **System Users**: Automatic Linux system account creation per SudoCell user
- **File Ownership**: All files owned by respective user account

### 2. User Management 👥
- Create new hosting accounts: `sudocell create-user`
- Delete users: `sudocell delete-user`
- List all users: `sudocell list-users`
- Change password: `sudocell change-password`
- Admin-only operations with privilege checks

### 3. Website Management 🌐
- Create websites owned by specific user
- Files stored in `/home/{user}/public_html/{domain}/`
- Automatic file/directory ownership
- Domain registration in database
- Per-domain logging and backups

### 4. FTP/SFTP Access 📁
- **SFTP**: SSH-based Secure File Transfer (recommended)
- **FTP**: VSFTPD with PAM authentication
- Users authenticate with their SudoCell credentials
- Access restricted to home directory only
- SFTP-only shell prevents shell commands

### 5. Database Integration 🗄️
- SQLite user database at `/etc/sudocell/users.db`
- New `websites` table for domain ownership
- New `db_servers` table for database credentials
- Per-user database access control
- Foreign key relationships maintain data integrity

### 6. Security Enhancements 🔒
- Password hashing: SHA-256
- Session management with file-based persistence
- PAM integration for FTP authentication
- SSH/SFTP-only shell for file access
- Admin privilege checks on sensitive commands
- Filesystem-level access control

## What's New in v0.2.0

### Code Changes
- **sudocell_auth.py**: System user creation, user management methods
- **feature_static_website.py**: Per-user website isolation, ownership tracking
- **sudocell_cli.py**: User management commands, privilege enforcement
- **sudocell_ftp.py**: NEW - FTP/SFTP configuration and management
- **install.sh**: VSFTPD/SSH integration, database schema updates

### Database Schema Additions
```sql
-- New field
ALTER TABLE users ADD COLUMN system_user INTEGER DEFAULT 0;

-- New table
CREATE TABLE websites (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  domain TEXT UNIQUE NOT NULL,
  path TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  enabled INTEGER DEFAULT 1,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### New CLI Commands
```bash
sudocell create-user --username user1 --email user@example.com
sudocell list-users
sudocell delete-user --username user1
sudocell change-password --username user1
```

### Configuration Changes
- Added `ENABLE_FTP=y` to sudocell.env
- VSFTPD PAM configuration for user authentication
- SSH SFTP subsystem activation
- Home directory skeleton creation

## File Structure Changes

### Before (v0.1.2)
```
./websites/
├── example.com/
│   ├── public/
│   ├── logs/
│   └── config.json
```

### After (v0.2.0)
```
/home/alice/
├── public_html/
│   ├── example.com/
│   │   ├── public/
│   │   ├── logs/
│   │   └── .sudocell.json
│   └── another.com/
└── .ssh/
```

## Installation Changes

### Dependencies Added
- `vsftpd` - FTP daemon
- `openssh-server` - SSH/SFTP

### Installation Process
1. Downloads and installs .deb package
2. Creates admin account (no system user for admin)
3. Initializes SQLite database with new schema
4. Configures VSFTPD with PAM authentication
5. Sets up SSH SFTP subsystem
6. Creates home directory skeleton
7. Starts all services

## Breaking Changes

⚠️ **Important**: v0.2.0 changes file storage locations

- Websites no longer stored in `./websites/`
- New default: `/home/{username}/public_html/{domain}/`
- Old installations need migration script
- System users created automatically for new accounts
- Password hashing remains SHA-256 (backward compatible)

## Upgrade Path

### From v0.1.2 → v0.2.0

**Manual Steps Required**:
1. Backup `/etc/sudocell/users.db` before upgrade
2. Run installer: `sudo bash uninstall.sh && curl ... | sudo bash`
3. Migration handles:
   - Creating system users for existing database users
   - Moving website files to `/home/{user}/public_html/`
   - Updating database with new paths
   - Resetting file permissions

```bash
# Backup
sudo cp -r /etc/sudocell /etc/sudocell.backup

# Uninstall v0.1.2 (keeps data)
sudo bash uninstall.sh  # Select 'no' to keep data

# Install v0.2.0
curl -fsSL https://raw.githubusercontent.com/.../install.sh | sudo bash
```

## Performance Impact

- **Minimal**: File operations now isolated by OS permissions
- **Improved**: SFTP faster than FTP for large files
- **Database**: Additional tables minimal overhead
- **Storage**: Same as v0.1.2 (files stored locally)

## Bug Fixes

- Fixed: Create website without proper user context
- Fixed: Website files not owned by user
- Fixed: No FTP access for users
- Fixed: Database users not isolated
- Fixed: Admin privilege checking missing

## Known Limitations

- SSH shell access still disabled (nologin)
- Cron jobs not yet supported
- Email forwarding not implemented
- Bandwidth tracking not available
- Backup automation planned for v0.3

## Testing Performed

✅ User account creation
✅ System user creation
✅ Website file isolation
✅ FTP authentication
✅ SFTP access
✅ Database registration
✅ Permission enforcement
✅ Admin privilege checks
✅ Password changes
✅ User deletion

## Future Roadmap (v0.3+)

- Automated backups
- Email forwarding setup
- Cron job management
- Bandwidth/resource limits
- SSL certificate automation
- Apache/Nginx config generation
- CLI auto-completion
- Web UI dashboard

## Documentation

See `MULTITENANT_ARCHITECTURE.md` for:
- Complete architecture documentation
- File structure and isolation
- Security layers
- User workflows
- Troubleshooting guide
- Production deployment recommendations

## Support

For issues or questions:
1. Check `MULTITENANT_ARCHITECTURE.md`
2. Review installation logs: `sudo tail -f /var/log/sudocell/*`
3. Verify permissions: `sudo ls -la /home/username/`
4. Test SFTP: `sftp username@localhost`

## Acknowledgments

Built with focus on:
- Professional hosting provider standards
- Multi-tenant security best practices
- File isolation and user management
- Linux ecosystem integration
- Production-grade reliability

## License

SudoCell v0.2.0 - Professional Hosting Control Panel
February 13, 2026

---

**Status**: ✅ Production Ready
**Recommendation**: 🚀 Deploy to live servers
