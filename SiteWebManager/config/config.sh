#!/bin/bash
# Configuration globale pour SiteWeb Manager

# Répertoires du système
WWW_DIR="/var/www/html"
APACHE_AVAILABLE="/etc/apache2/sites-available"
APACHE_ENABLED="/etc/apache2/sites-enabled"
BACKUP_DIR="/var/backups/siteweb-manager"
LOG_DIR="/var/log/siteweb-manager"

# Configuration des permissions
DEFAULT_OWNER="www-data:www-data"
DEFAULT_PERMISSIONS="755"
DEFAULT_FILE_PERMISSIONS="644"

# Configuration des logs
ENABLE_LOGGING=true
LOG_LEVEL="INFO"  # DEBUG, INFO, WARNING, ERROR
ROTATE_LOGS=true
MAX_LOG_SIZE_MB=10

# Configuration par défaut
DEFAULT_HTTP_PORT=80
DEFAULT_HTTPS_PORT=443
DEFAULT_SSH_PORT=22
CREATE_DEFAULT_INDEX=true
BACKUP_BEFORE_CHANGES=true

# Configuration Apache
APACHE_TIMEOUT=300
APACHE_KEEPALIVE="On"
APACHE_MAX_KEEPALIVE_REQUESTS=100
APACHE_KEEPALIVE_TIMEOUT=5

# Configuration SSL
SSL_CERT_DIR="/etc/letsencrypt/live"
SSL_CHALLENGE_TYPE="http"

# Sécurité
ENABLE_UFW=true
FAIL2BAN_ENABLED=true

# Version du script
VERSION="2.1.1"

# Configuration PHP
DEFAULT_PHP_VERSION="7.4"
PHP_MEMORY_LIMIT="256M"
PHP_MAX_EXECUTION_TIME=30
PHP_UPLOAD_MAX_FILESIZE="64M"
PHP_POST_MAX_SIZE="64M"

# Configuration MariaDB/MySQL
DB_ROOT_USER="root"
DB_DATA_DIR="/var/lib/mysql"
DB_MAX_CONNECTIONS=100

# Mise à jour automatique
CHECK_FOR_UPDATES=true
UPDATE_URL="https://example.com/updates/siteweb-manager"
AUTO_UPDATE=false  # Désactivé par défaut pour la sécurité 