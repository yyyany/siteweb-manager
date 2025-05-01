#!/bin/bash
# Fonctions de gestion d'Apache

# Fonction pour installer Apache
install_apache() {
    log_info "Installation d'Apache..."
    
    # Mise à jour des paquets
    apt update
    
    # Installation d'Apache
    if apt install -y apache2; then
        log_info "Apache installé avec succès"
        
        # Configuration de base
        configure_apache
        
        # Activation du service
        systemctl enable apache2
        systemctl start apache2
        
        log_info "Apache configuré et démarré"
        return 0
    else
        log_error "Échec de l'installation d'Apache"
        return 1
    fi
}

# Fonction pour configurer Apache
configure_apache() {
    log_info "Configuration d'Apache..."
    
    # Sauvegarde de la configuration actuelle
    backup_file "/etc/apache2/apache2.conf"
    
    # Configuration de base
    cat > /etc/apache2/apache2.conf << EOF
# Configuration de base Apache
ServerName localhost
ServerAdmin webmaster@localhost
ServerTokens Prod
ServerSignature Off

# Configuration des logs
ErrorLog \${APACHE_LOG_DIR}/error.log
CustomLog \${APACHE_LOG_DIR}/access.log combined

# Configuration des modules
LoadModule mpm_event_module /usr/lib/apache2/modules/mod_mpm_event.so
LoadModule authz_core_module /usr/lib/apache2/modules/mod_authz_core.so
LoadModule dir_module /usr/lib/apache2/modules/mod_dir.so
LoadModule mime_module /usr/lib/apache2/modules/mod_mime.so
LoadModule log_config_module /usr/lib/apache2/modules/mod_log_config.so
LoadModule env_module /usr/lib/apache2/modules/mod_env.so
LoadModule setenvif_module /usr/lib/apache2/modules/mod_setenvif.so
LoadModule headers_module /usr/lib/apache2/modules/mod_headers.so
LoadModule ssl_module /usr/lib/apache2/modules/mod_ssl.so

# Configuration des répertoires
<Directory />
    Options FollowSymLinks
    AllowOverride None
    Require all denied
</Directory>

<Directory /var/www/>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>

# Configuration des fichiers
<FilesMatch "^\.ht">
    Require all denied
</FilesMatch>

# Configuration des en-têtes de sécurité
<IfModule mod_headers.c>
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Content-Security-Policy "default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; connect-src 'self'"
</IfModule>
EOF
    
    # Activation des modules nécessaires
    a2enmod headers
    a2enmod ssl
    a2enmod rewrite
    
    # Redémarrage d'Apache
    systemctl restart apache2
    
    log_info "Apache configuré avec succès"
    return 0
}

# Fonction pour gérer le service Apache
manage_apache_service() {
    local action=$1
    
    case "$action" in
        "start")
            log_info "Démarrage d'Apache..."
            systemctl start apache2
            ;;
        "stop")
            log_info "Arrêt d'Apache..."
            systemctl stop apache2
            ;;
        "restart")
            log_info "Redémarrage d'Apache..."
            systemctl restart apache2
            ;;
        "status")
            log_info "Statut d'Apache..."
            systemctl status apache2
            ;;
        *)
            log_error "Action invalide: $action"
            return 1
            ;;
    esac
    
    return 0
}

# Fonction pour vérifier la configuration Apache
check_apache_config() {
    log_info "Vérification de la configuration Apache..."
    
    # Vérification de la syntaxe
    if apache2ctl configtest; then
        log_info "La configuration Apache est valide"
        return 0
    else
        log_error "La configuration Apache contient des erreurs"
        return 1
    fi
}

# Fonction pour lister les modules Apache
list_apache_modules() {
    log_info "Liste des modules Apache..."
    
    echo -e "${BLUE}=== Modules Apache ===${NC}"
    apache2ctl -M | sort
}

# Fonction pour activer/désactiver un module Apache
toggle_apache_module() {
    local module=$1
    local action=$2
    
    case "$action" in
        "enable")
            log_info "Activation du module $module..."
            a2enmod "$module"
            ;;
        "disable")
            log_info "Désactivation du module $module..."
            a2dismod "$module"
            ;;
        *)
            log_error "Action invalide: $action"
            return 1
            ;;
    esac
    
    # Redémarrage d'Apache si nécessaire
    if [[ $? -eq 0 ]]; then
        systemctl restart apache2
        log_info "Module $module $action avec succès"
        return 0
    else
        log_error "Échec de l'action $action sur le module $module"
        return 1
    fi
} 