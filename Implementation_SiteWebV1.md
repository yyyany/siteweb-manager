# Guide d'Implémentation - Script de Gestion de Serveur Web

## Table des matières
1. [Introduction](#introduction)
2. [Structure du projet](#structure-du-projet)
3. [Implémentation des modules](#implémentation-des-modules)
4. [Mise en œuvre des améliorations](#mise-en-œuvre-des-améliorations)
5. [Tests et déploiement](#tests-et-déploiement)

## Introduction

Ce document fournit un guide détaillé pour implémenter une version améliorée du script SiteWebV1.sh, en le transformant en une solution modulaire, extensible et professionnelle pour la gestion de serveurs web. L'implémentation suivra les meilleures pratiques de développement bash et adoptera une architecture modulaire.

## Structure du projet

Voici la structure de fichiers recommandée pour la nouvelle implémentation :

```
SiteWebManager/
├── siteweb-manager.sh       # Script principal (point d'entrée)
├── config/                  # Configuration
│   ├── config.sh            # Variables de configuration
│   └── colors.sh            # Définitions des couleurs
├── lib/                     # Bibliothèques de fonctions
│   ├── utils.sh             # Fonctions utilitaires
│   ├── system.sh            # Fonctions système
│   ├── apache.sh            # Fonctions Apache
│   ├── sites.sh             # Fonctions gestion de sites
│   ├── ssl.sh               # Fonctions SSL/HTTPS
│   ├── db.sh                # Fonctions base de données
│   └── php.sh               # Fonctions PHP
├── ui/                      # Interface utilisateur
│   ├── menus.sh             # Définitions des menus
│   └── display.sh           # Fonctions d'affichage
├── tests/                   # Tests
│   └── run_tests.sh         # Script de tests
├── docs/                    # Documentation
│   └── README.md            # Documentation utilisateur
└── install.sh               # Script d'installation
```

## Implémentation des modules

### Script principal (siteweb-manager.sh)

```bash
#!/bin/bash
# SiteWeb Manager - Script de gestion de serveur web
VERSION="2.0.0"

# Détection du chemin du script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$SCRIPT_DIR"

# Chargement de la configuration
source "$BASE_DIR/config/config.sh"
source "$BASE_DIR/config/colors.sh"

# Chargement des modules
source "$BASE_DIR/lib/utils.sh"
source "$BASE_DIR/lib/system.sh"
source "$BASE_DIR/lib/apache.sh"
source "$BASE_DIR/lib/sites.sh"
source "$BASE_DIR/lib/ssl.sh"
source "$BASE_DIR/lib/db.sh"
source "$BASE_DIR/lib/php.sh"

# Chargement de l'interface utilisateur
source "$BASE_DIR/ui/display.sh"
source "$BASE_DIR/ui/menus.sh"

# Vérification des prérequis
check_prerequisites

# Lancement du menu principal
show_main_menu
```

### Configuration (config/config.sh)

```bash
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
```

### Couleurs (config/colors.sh)

```bash
#!/bin/bash
# Définition des couleurs pour l'affichage

# Couleurs de base
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Styles
BOLD='\033[1m'
UNDERLINE='\033[4m'
INVERTED='\033[7m'
```

### Fonctions utilitaires (lib/utils.sh)

```bash
#!/bin/bash
# Fonctions utilitaires partagées

# Fonction de journalisation améliorée
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    
    # Sélection de la couleur selon le niveau
    local color=""
    case "$level" in
        "DEBUG") color="${GRAY}" ;;
        "INFO") color="${GREEN}" ;;
        "WARNING") color="${YELLOW}" ;;
        "ERROR") color="${RED}" ;;
        *) color="${NC}" ;;
    esac
    
    # Affichage console selon niveau configuré
    if [[ "$ENABLE_LOGGING" == true ]]; then
        case "$LOG_LEVEL" in
            "DEBUG") 
                echo -e "${color}[$timestamp] [$level] $message${NC}" ;;
            "INFO") 
                if [[ "$level" != "DEBUG" ]]; then
                    echo -e "${color}[$timestamp] [$level] $message${NC}"
                fi
                ;;
            "WARNING") 
                if [[ "$level" != "DEBUG" && "$level" != "INFO" ]]; then
                    echo -e "${color}[$timestamp] [$level] $message${NC}"
                fi
                ;;
            "ERROR") 
                if [[ "$level" == "ERROR" ]]; then
                    echo -e "${color}[$timestamp] [$level] $message${NC}"
                fi
                ;;
        esac
        
        # Enregistrement dans le fichier de log
        if [[ ! -d "$LOG_DIR" ]]; then
            mkdir -p "$LOG_DIR"
        fi
        
        echo "[$timestamp] [$level] $message" >> "$LOG_DIR/siteweb-manager.log"
        
        # Rotation des logs si nécessaire
        if [[ -f "$LOG_DIR/siteweb-manager.log" ]]; then
            local log_size=$(du -m "$LOG_DIR/siteweb-manager.log" | cut -f1)
            if (( log_size > MAX_LOG_SIZE_MB )); then
                mv "$LOG_DIR/siteweb-manager.log" "$LOG_DIR/siteweb-manager.log.$(date +'%Y%m%d%H%M%S')"
                touch "$LOG_DIR/siteweb-manager.log"
            fi
        fi
    fi
}

# Alias pour les différents niveaux de log
log_debug() { log "DEBUG" "$1"; }
log_info() { log "INFO" "$1"; }
log_warning() { log "WARNING" "$1"; }
log_error() { log "ERROR" "$1"; }

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fonction pour vérifier les prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    # Vérifier si le script est exécuté avec sudo
    if [[ $EUID -ne 0 ]]; then
        log_error "Ce script doit être exécuté avec des privilèges sudo."
        exit 1
    fi
    
    # Vérifier que nous sommes sur un système Debian/Ubuntu
    if ! command_exists apt-get; then
        log_error "Ce script nécessite un système basé sur Debian/Ubuntu."
        exit 1
    fi
    
    # Vérifier les commandes essentielles
    local required_commands=("grep" "awk" "sed" "netstat" "host")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_warning "Commandes manquantes: ${missing_commands[*]}"
        log_info "Installation des dépendances manquantes..."
        
        # Installer net-tools si netstat manquant
        if [[ " ${missing_commands[*]} " =~ " netstat " ]]; then
            apt-get update
            apt-get install -y net-tools
        fi
        
        # Installer dnsutils ou bind9-utils si host manquant
        if [[ " ${missing_commands[*]} " =~ " host " ]]; then
            apt-get update
            apt-get install -y dnsutils
        fi
    fi
    
    log_info "Prérequis vérifiés avec succès."
}

# Fonction pour obtenir l'adresse IP du serveur
get_server_ip() {
    hostname -I | cut -d' ' -f1
}

# Fonction pour valider un nom de domaine
validate_domain() {
    local domain=$1
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi
    return 0
}

# Fonction pour valider un numéro de port
validate_port() {
    local port=$1
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi
    return 0
}

# Fonction pour créer une sauvegarde d'un fichier
backup_file() {
    local file=$1
    local backup_dir="$LOG_DIR/backups"
    local timestamp=$(date +'%Y%m%d%H%M%S')
    local backup_file="$backup_dir/$(basename "$file").$timestamp"
    
    if [[ ! -d "$backup_dir" ]]; then
        mkdir -p "$backup_dir"
    fi
    
    if [[ -f "$file" ]]; then
        cp "$file" "$backup_file"
        log_info "Sauvegarde créée: $backup_file"
        return 0
    else
        log_warning "Impossible de sauvegarder. Le fichier n'existe pas: $file"
        return 1
    fi
}
```

### Système (lib/system.sh)

```bash
#!/bin/bash
# Fonctions de gestion système

# Fonction pour mettre à jour le système
update_system() {
    log_info "Début de la mise à jour du système..."
    
    # Mise à jour de la liste des paquets
    log_info "Mise à jour de la liste des paquets..."
    if apt update; then
        log_info "Liste des paquets mise à jour avec succès"
    else
        log_error "Échec de la mise à jour de la liste des paquets"
        return 1
    fi

    # Mise à niveau des paquets
    log_info "Installation des mises à jour..."
    if apt upgrade -y; then
        log_info "Système mis à jour avec succès"
    else
        log_error "Échec de la mise à jour du système"
        return 1
    fi

    # Nettoyage
    log_info "Nettoyage des paquets obsolètes..."
    if apt autoremove -y && apt clean; then
        log_info "Nettoyage terminé avec succès"
    else
        log_error "Échec du nettoyage"
        return 1
    fi

    log_info "Mise à jour du système terminée"
    return 0
}

# Fonction pour configurer le pare-feu
configure_firewall() {
    log_info "Configuration du pare-feu..."
    
    # Vérifier si ufw est installé
    if ! command_exists ufw; then
        log_info "Installation de ufw..."
        apt update
        apt install -y ufw
    fi
    
    # Vérifier le statut actuel
    local ufw_status=$(ufw status | grep "Status" | awk '{print $2}')
    
    # Configurer les règles de base
    log_info "Configuration des règles de base..."
    
    # Autoriser SSH
    ufw allow "$DEFAULT_SSH_PORT/tcp" comment "SSH"
    
    # Autoriser HTTP et HTTPS
    ufw allow "$DEFAULT_HTTP_PORT/tcp" comment "HTTP"
    ufw allow "$DEFAULT_HTTPS_PORT/tcp" comment "HTTPS"
    
    # Activer le pare-feu s'il n'est pas déjà actif
    if [[ "$ufw_status" != "active" ]]; then
        log_info "Activation du pare-feu..."
        echo "y" | ufw enable
    fi
    
    log_info "Pare-feu configuré avec succès"
    return 0
}

# Fonction pour afficher les informations système
show_system_info() {
    log_info "Collecte des informations système..."
    
    # Informations sur le système d'exploitation
    echo -e "${BLUE}=== Informations système ===${NC}"
    echo -e "${YELLOW}Système :${NC} $(lsb_release -ds 2>/dev/null || cat /etc/*release | grep PRETTY_NAME | cut -d= -f2- | tr -d '"')"
    echo -e "${YELLOW}Noyau :${NC} $(uname -r)"
    echo -e "${YELLOW}Architecture :${NC} $(uname -m)"
    
    # Informations sur le processeur
    echo -e "\n${BLUE}=== Processeur ===${NC}"
    echo -e "${YELLOW}Modèle :${NC} $(grep "model name" /proc/cpuinfo | head -n1 | cut -d: -f2- | sed 's/^[ \t]*//')"
    echo -e "${YELLOW}Cœurs :${NC} $(grep -c "processor" /proc/cpuinfo)"
    
    # Informations sur la mémoire
    echo -e "\n${BLUE}=== Mémoire ===${NC}"
    echo -e "${YELLOW}Mémoire totale :${NC} $(free -h | grep Mem | awk '{print $2}')"
    echo -e "${YELLOW}Mémoire utilisée :${NC} $(free -h | grep Mem | awk '{print $3}')"
    
    # Informations sur le disque
    echo -e "\n${BLUE}=== Disque ===${NC}"
    df -h / | tail -n +2 | awk '{print "Total: " $2 ", Utilisé: " $3 ", Disponible: " $4 ", Utilisation: " $5}'
    
    # Informations sur le réseau
    echo -e "\n${BLUE}=== Réseau ===${NC}"
    echo -e "${YELLOW}Adresse IP :${NC} $(get_server_ip)"
    echo -e "${YELLOW}Nom d'hôte :${NC} $(hostname)"
    
    # Informations sur Apache (si installé)
    if command_exists apache2; then
        echo -e "\n${BLUE}=== Apache ===${NC}"
        echo -e "${YELLOW}Version :${NC} $(apache2 -v | grep version | awk -F'[ /]' '{print $4}')"
        echo -e "${YELLOW}Statut :${NC} $(systemctl is-active apache2)"
        
        # Sites actifs
        echo -e "${YELLOW}Sites actifs :${NC} $(ls -l $APACHE_ENABLED | grep -v ^total | wc -l)"
    fi
    
    # Informations sur PHP (si installé)
    if command_exists php; then
        echo -e "\n${BLUE}=== PHP ===${NC}"
        echo -e "${YELLOW}Version :${NC} $(php -v | head -n1 | cut -d' ' -f2)"
    fi
    
    # Informations sur MySQL/MariaDB (si installé)
    if command_exists mysql; then
        echo -e "\n${BLUE}=== Base de données ===${NC}"
        local db_version=$(mysql --version)
        if [[ "$db_version" == *"MariaDB"* ]]; then
            echo -e "${YELLOW}Type :${NC} MariaDB"
        else
            echo -e "${YELLOW}Type :${NC} MySQL"
        fi
        echo -e "${YELLOW}Version :${NC} $(echo $db_version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')"
        echo -e "${YELLOW}Statut :${NC} $(systemctl is-active mysql mariadb 2>/dev/null)"
    fi
    
    log_info "Collecte des informations système terminée"
}
```

## Mise en œuvre des améliorations

### Implémentation d'Apache améliorée (lib/apache.sh)

L'implémentation d'Apache doit inclure des fonctionnalités avancées comme :

1. **Gestion des modules** - Activation/désactivation avec dépendances
2. **Configuration sécurisée** - Application des meilleures pratiques OWASP
3. **Monitoring et performances** - Collecte de métriques et optimisation

Exemple de fonction pour la configuration sécurisée :

```bash
# Configuration des paramètres de sécurité Apache
secure_apache() {
    log_info "Application des paramètres de sécurité Apache..."
    
    # Vérifier que les modules de sécurité sont activés
    a2enmod headers
    a2enmod ssl
    
    # Configurer le fichier security.conf
    local security_conf="/etc/apache2/conf-available/security.conf"
    backup_file "$security_conf"
    
    # Modifier les paramètres de sécurité
    sed -i 's/^ServerTokens.*/ServerTokens Prod/' "$security_conf"
    sed -i 's/^ServerSignature.*/ServerSignature Off/' "$security_conf"
    
    # Ajouter des en-têtes de sécurité
    if ! grep -q "X-Content-Type-Options" "$security_conf"; then
        cat >> "$security_conf" << EOF

# En-têtes de sécurité supplémentaires
<IfModule mod_headers.c>
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Content-Security-Policy "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; connect-src 'self'"
</IfModule>
EOF
    fi
    
    # Activer la configuration de sécurité
    a2enconf security
    
    # Redémarrer Apache pour appliquer les changements
    systemctl restart apache2
    
    log_info "Paramètres de sécurité Apache appliqués avec succès"
}
```

### Module de gestion de base de données (lib/db.sh)

```bash
#!/bin/bash
# Fonctions de gestion de base de données

# Installer MariaDB
install_mariadb() {
    log_info "Installation de MariaDB..."
    
    # Mise à jour des paquets
    apt update
    
    # Installation de MariaDB
    if apt install -y mariadb-server; then
        log_info "MariaDB installé avec succès"
        
        # Sécuriser l'installation
        log_info "Sécurisation de l'installation MariaDB..."
        secure_mariadb
        
        # Activer et démarrer le service
        systemctl enable mariadb
        systemctl start mariadb
        
        log_info "MariaDB configuré et démarré"
        return 0
    else
        log_error "Échec de l'installation de MariaDB"
        return 1
    fi
}

# Sécuriser l'installation MariaDB
secure_mariadb() {
    log_info "Exécution du script de sécurisation MariaDB..."
    
    # Génération d'un mot de passe root aléatoire
    local root_pw=$(openssl rand -base64 16)
    
    # Création du fichier de configuration pour mysql_secure_installation
    cat > /tmp/mysql_secure_installation.sql << EOF
-- Change root password
UPDATE mysql.user SET Password=PASSWORD('${root_pw}') WHERE User='root';
-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';
-- Disallow remote root login
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- Reload privilege tables
FLUSH PRIVILEGES;
EOF

    # Exécution du script
    mysql < /tmp/mysql_secure_installation.sql
    
    # Suppression du fichier temporaire
    rm -f /tmp/mysql_secure_installation.sql
    
    # Sauvegarde du mot de passe dans un fichier sécurisé
    echo "MariaDB Root Password: $root_pw" > /root/.mariadb_root
    chmod 600 /root/.mariadb_root
    
    log_info "Installation MariaDB sécurisée. Mot de passe root sauvegardé dans /root/.mariadb_root"
}

# Créer une base de données
create_database() {
    local db_name=$1
    local db_user=$2
    local db_password=$3
    
    # Validation des paramètres
    if [[ -z "$db_name" || -z "$db_user" || -z "$db_password" ]]; then
        log_error "Paramètres manquants pour la création de la base de données"
        return 1
    fi
    
    log_info "Création de la base de données $db_name pour l'utilisateur $db_user..."
    
    # Récupération du mot de passe root
    local root_pw=""
    if [[ -f /root/.mariadb_root ]]; then
        root_pw=$(grep "MariaDB Root Password" /root/.mariadb_root | cut -d' ' -f4)
    fi
    
    # Création de la base et de l'utilisateur
    if [[ -n "$root_pw" ]]; then
        mysql -u root -p"$root_pw" << EOF
CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
EOF
    else
        mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
EOF
    fi
    
    if [[ $? -eq 0 ]]; then
        log_info "Base de données $db_name et utilisateur $db_user créés avec succès"
        return 0
    else
        log_error "Échec de la création de la base de données"
        return 1
    fi
}

# Lister les bases de données
list_databases() {
    log_info "Liste des bases de données..."
    
    # Récupération du mot de passe root
    local root_pw=""
    if [[ -f /root/.mariadb_root ]]; then
        root_pw=$(grep "MariaDB Root Password" /root/.mariadb_root | cut -d' ' -f4)
    fi
    
    # Afficher la liste des bases
    echo -e "${BLUE}=== Bases de données ===${NC}"
    
    if [[ -n "$root_pw" ]]; then
        mysql -u root -p"$root_pw" -e "SHOW DATABASES;" | grep -v "Database\|information_schema\|mysql\|performance_schema"
    else
        mysql -u root -e "SHOW DATABASES;" | grep -v "Database\|information_schema\|mysql\|performance_schema"
    fi
}
```

### Gestion PHP (lib/php.sh)

```bash
#!/bin/bash
# Fonctions de gestion de PHP

# Installer PHP et ses extensions de base
install_php() {
    local php_version=$1
    
    if [[ -z "$php_version" ]]; then
        php_version="7.4"  # Version par défaut
    fi
    
    log_info "Installation de PHP $php_version..."
    
    # Mise à jour des paquets
    apt update
    
    # Installation PHP et extensions principales
    if apt install -y php$php_version php$php_version-common php$php_version-mysql php$php_version-cli \
       php$php_version-gd php$php_version-curl php$php_version-mbstring php$php_version-xml \
       php$php_version-zip php$php_version-intl libapache2-mod-php$php_version; then
        
        log_info "PHP $php_version installé avec succès"
        
        # Configuration de PHP pour Apache
        a2enmod php$php_version
        systemctl restart apache2
        
        log_info "PHP configuré pour Apache"
        return 0
    else
        log_error "Échec de l'installation de PHP $php_version"
        return 1
    fi
}

# Installer plusieurs versions de PHP
install_multiple_php() {
    log_info "Installation de plusieurs versions de PHP..."
    
    # Ajout du dépôt PPA
    if ! command_exists add-apt-repository; then
        apt install -y software-properties-common
    fi
    
    # Ajout du dépôt PHP
    add-apt-repository -y ppa:ondrej/php
    apt update
    
    # Installation des différentes versions
    install_php 7.4
    install_php 8.0
    install_php 8.1
    
    # Installation de PHP-FPM pour chaque version
    apt install -y php7.4-fpm php8.0-fpm php8.1-fpm
    
    # Activation des modules nécessaires
    a2enmod proxy_fcgi setenvif
    
    # Configuration d'Apache pour PHP-FPM
    a2enconf php7.4-fpm php8.0-fpm php8.1-fpm
    
    systemctl restart apache2
    
    log_info "Plusieurs versions de PHP installées avec succès"
}

# Configurer php.ini
configure_php() {
    local php_version=$1
    
    if [[ -z "$php_version" ]]; then
        php_version="7.4"  # Version par défaut
    fi
    
    log_info "Configuration de PHP $php_version..."
    
    local php_ini="/etc/php/$php_version/apache2/php.ini"
    
    # Sauvegarde du fichier original
    backup_file "$php_ini"
    
    # Modification des paramètres courants
    sed -i 's/^memory_limit.*/memory_limit = 256M/' "$php_ini"
    sed -i 's/^upload_max_filesize.*/upload_max_filesize = 64M/' "$php_ini"
    sed -i 's/^post_max_size.*/post_max_size = 64M/' "$php_ini"
    sed -i 's/^max_execution_time.*/max_execution_time = 300/' "$php_ini"
    sed -i 's/^display_errors.*/display_errors = Off/' "$php_ini"
    sed -i 's/^display_startup_errors.*/display_startup_errors = Off/' "$php_ini"
    sed -i 's/^error_reporting.*/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT/' "$php_ini"
    
    # Redémarrage d'Apache
    systemctl restart apache2
    
    log_info "PHP $php_version configuré avec succès"
}
```

## Tests et déploiement

### Script de test (tests/run_tests.sh)

```bash
#!/bin/bash
# Script de tests pour SiteWeb Manager

# Détection du chemin du script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Chargement de la configuration
source "$BASE_DIR/config/config.sh"
source "$BASE_DIR/config/colors.sh"
source "$BASE_DIR/lib/utils.sh"

# Variables de test
TEST_DOMAIN="test.example.com"
TEST_SITE_DIR="/tmp/test-site"
TEST_PASSED=0
TEST_FAILED=0
TEST_TOTAL=0

# Fonction pour exécuter un test
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    
    echo -e "${YELLOW}Test: ${test_name}${NC}"
    ((TEST_TOTAL++))
    
    if eval "$test_cmd"; then
        echo -e "${GREEN}✓ Réussi${NC}"
        ((TEST_PASSED++))
    else
        echo -e "${RED}✗ Échoué${NC}"
        ((TEST_FAILED++))
    fi
    echo ""
}

# Préparation de l'environnement de test
setup_test_env() {
    echo -e "${BLUE}=== Préparation de l'environnement de test ===${NC}"
    
    # Création d'un site de test
    mkdir -p "$TEST_SITE_DIR"
    echo "<html><body><h1>Site de test</h1></body></html>" > "$TEST_SITE_DIR/index.html"
    
    echo -e "${GREEN}✓ Environnement de test préparé${NC}\n"
}

# Nettoyage de l'environnement de test
cleanup_test_env() {
    echo -e "${BLUE}=== Nettoyage de l'environnement de test ===${NC}"
    
    # Suppression du site de test
    rm -rf "$TEST_SITE_DIR"
    
    echo -e "${GREEN}✓ Environnement de test nettoyé${NC}\n"
}

# Exécution des tests
run_tests() {
    echo -e "${BLUE}=== Démarrage des tests ===${NC}\n"
    
    # Tests des fonctions utilitaires
    run_test "Validation domaine (valide)" "validate_domain 'example.com'"
    run_test "Validation domaine (invalide)" "! validate_domain 'invalid domain'"
    run_test "Validation port (valide)" "validate_port 80"
    run_test "Validation port (invalide)" "! validate_port 999999"
    
    # Tests du système
    if [[ $EUID -eq 0 ]]; then
        run_test "Vérification des prérequis" "check_prerequisites"
    else
        echo -e "${YELLOW}Tests système ignorés - nécessite sudo${NC}\n"
    fi
    
    # Affichage des résultats
    echo -e "${BLUE}=== Résultats des tests ===${NC}"
    echo -e "Tests total: $TEST_TOTAL"
    echo -e "${GREEN}Tests réussis: $TEST_PASSED${NC}"
    echo -e "${RED}Tests échoués: $TEST_FAILED${NC}"
    
    # Retour d'état global
    if [[ $TEST_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}✓ Tous les tests ont réussi${NC}"
        return 0
    else
        echo -e "\n${RED}✗ Certains tests ont échoué${NC}"
        return 1
    fi
}

# Exécution principale
setup_test_env
run_tests
cleanup_test_env
```

### Script d'installation (install.sh)

```bash
#!/bin/bash
# Script d'installation du gestionnaire de site web
VERSION="2.0.0"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour les messages de log
log_message() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Fonction pour les messages d'erreur
log_error() {
    echo -e "${RED}[ERREUR] $1${NC}"
}

# Vérification des privilèges sudo
if [[ $EUID -ne 0 ]]; then
    log_error "Ce script doit être exécuté avec des privilèges sudo."
    exit 1
fi

# Détection du répertoire d'installation
INSTALL_DIR="/opt/siteweb-manager"

# Affichage du message d'introduction
clear
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}    ${GREEN}Installation SiteWeb Manager v$VERSION${NC}    ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

log_message "Bienvenue dans l'installation du gestionnaire de site web"
echo -e "Ce script va installer SiteWeb Manager dans $INSTALL_DIR\n"

# Demande de confirmation
read -p "$(echo -e ${YELLOW}Souhaitez-vous continuer l'installation? (o/n)${NC}: )" confirm
if [[ "$confirm" != "o" && "$confirm" != "O" ]]; then
    echo -e "\n${RED}Installation annulée${NC}"
    exit 0
fi

# Mise à jour du système
log_message "Mise à jour du système..."
apt update

# Installation des dépendances
log_message "Installation des dépendances..."
apt install -y curl wget git zip unzip dialog net-tools dnsutils

# Création du répertoire d'installation
log_message "Création du répertoire d'installation..."
mkdir -p "$INSTALL_DIR"

# Copie des fichiers
log_message "Copie des fichiers..."
cp -r ./* "$INSTALL_DIR/"

# Définition des permissions
log_message "Configuration des permissions..."
chmod +x "$INSTALL_DIR/siteweb-manager.sh"
chmod +x "$INSTALL_DIR/install.sh"
chmod +x "$INSTALL_DIR/tests/run_tests.sh"

# Création d'un lien symbolique
log_message "Création du lien symbolique..."
ln -sf "$INSTALL_DIR/siteweb-manager.sh" /usr/local/bin/siteweb-manager

# Création du fichier de configuration
log_message "Configuration initiale..."
mkdir -p "$INSTALL_DIR/config"

# Exécution des tests
log_message "Exécution des tests..."
bash "$INSTALL_DIR/tests/run_tests.sh"

# Message de fin
echo -e "\n${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  Installation terminée avec succès!        ${GREEN}║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}\n"

echo -e "Vous pouvez maintenant utiliser SiteWeb Manager en exécutant :"
echo -e "${YELLOW}siteweb-manager${NC}"
echo -e "\nBonne utilisation!"
```

Cette implementation constitue une base solide pour créer une version améliorée et modulaire du script original. Elle introduit une gestion des erreurs plus robuste, un meilleur système de journalisation, et des fonctionnalités supplémentaires comme la gestion de PHP et des bases de données. 