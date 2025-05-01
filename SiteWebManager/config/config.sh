#!/bin/bash
# Configuration du script SiteWeb Manager

# Chemins des répertoires
WWW_DIR="/var/www"
APACHE_AVAILABLE="/etc/apache2/sites-available"
APACHE_ENABLED="/etc/apache2/sites-enabled"
LOG_DIR="/var/log/siteweb-manager"

# Configuration par défaut
DEFAULT_HTTP_PORT=80
DEFAULT_HTTPS_PORT=443
DEFAULT_SSH_PORT=22

# Options de déploiement
CREATE_DEFAULT_INDEX=true
DEFAULT_PERMISSIONS=755
DEFAULT_OWNER="www-data:www-data"

# Logging
ENABLE_LOGGING=true
LOG_LEVEL="INFO"  # DEBUG, INFO, WARNING, ERROR
MAX_LOG_SIZE_MB=10

# Mise à jour automatique
CHECK_FOR_UPDATES=true
UPDATE_URL="https://example.com/updates/siteweb-manager" 