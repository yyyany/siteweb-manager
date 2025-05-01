#!/bin/bash
# Fonctions de gestion PHP

# Installer PHP et les extensions courantes
install_php() {
    local php_version=$1
    
    # Validation de la version
    if [[ -z "$php_version" ]]; then
        php_version="8.2"
    fi
    
    log_info "Installation de PHP $php_version et des extensions courantes..."
    
    # Mise à jour des paquets
    apt update
    
    # Installation des dépendances
    apt install -y software-properties-common
    add-apt-repository -y ppa:ondrej/php
    
    # Installation de PHP et des extensions courantes
    if apt install -y php$php_version \
        php$php_version-fpm \
        php$php_version-mysql \
        php$php_version-curl \
        php$php_version-gd \
        php$php_version-mbstring \
        php$php_version-xml \
        php$php_version-zip \
        php$php_version-intl \
        php$php_version-bcmath \
        php$php_version-opcache \
        php$php_version-redis \
        php$php_version-memcached; then
        
        log_info "PHP $php_version et les extensions installés avec succès"
        
        # Configuration de base
        configure_php "$php_version"
        
        # Activation et démarrage du service
        systemctl enable php$php_version-fpm
        systemctl start php$php_version-fpm
        
        log_info "PHP-FPM $php_version configuré et démarré"
        return 0
    else
        log_error "Échec de l'installation de PHP $php_version"
        return 1
    fi
}

# Configurer PHP
configure_php() {
    local php_version=$1
    
    # Validation de la version
    if [[ -z "$php_version" ]]; then
        php_version="8.2"
    fi
    
    log_info "Configuration de PHP $php_version..."
    
    # Sauvegarde des fichiers de configuration
    backup_file "/etc/php/$php_version/fpm/php.ini"
    backup_file "/etc/php/$php_version/fpm/pool.d/www.conf"
    
    # Configuration de php.ini
    cat > "/etc/php/$php_version/fpm/php.ini" << EOF
[PHP]
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
max_input_time = 300
max_input_vars = 3000
date.timezone = Europe/Paris
display_errors = Off
log_errors = On
error_log = /var/log/php$php_version-fpm/error.log
session.gc_maxlifetime = 1440
session.cookie_secure = 1
session.cookie_httponly = 1
session.use_strict_mode = 1
opcache.enable = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 60
opcache.fast_shutdown = 1
opcache.enable_cli = 1
EOF
    
    # Configuration du pool PHP-FPM
    cat > "/etc/php/$php_version/fpm/pool.d/www.conf" << EOF
[www]
user = www-data
group = www-data
listen = /run/php/php$php_version-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
php_admin_value[error_log] = /var/log/php$php_version-fpm/www-error.log
php_admin_flag[log_errors] = on
php_value[session.save_handler] = files
php_value[session.save_path] = /var/lib/php$php_version/sessions
php_value[soap.wsdl_cache_dir] = /var/lib/php$php_version/wsdlcache
EOF
    
    # Création des répertoires nécessaires
    mkdir -p /var/lib/php$php_version/sessions
    mkdir -p /var/lib/php$php_version/wsdlcache
    chown -R www-data:www-data /var/lib/php$php_version
    
    # Redémarrage de PHP-FPM
    systemctl restart php$php_version-fpm
    
    log_info "PHP $php_version configuré avec succès"
}

# Installer Composer
install_composer() {
    log_info "Installation de Composer..."
    
    # Téléchargement de l'installateur
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    
    # Vérification de la signature
    local expected_signature=$(curl -s https://composer.github.io/installer.sig)
    local actual_signature=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")
    
    if [[ "$expected_signature" != "$actual_signature" ]]; then
        log_error "Signature de l'installateur Composer invalide"
        rm composer-setup.php
        return 1
    fi
    
    # Installation
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm composer-setup.php
    
    if [[ $? -eq 0 ]]; then
        log_info "Composer installé avec succès"
        return 0
    else
        log_error "Échec de l'installation de Composer"
        return 1
    fi
}

# Installer une extension PHP
install_php_extension() {
    local extension=$1
    local php_version=$2
    
    # Validation des paramètres
    if [[ -z "$extension" ]]; then
        log_error "Nom de l'extension manquant"
        return 1
    fi
    
    if [[ -z "$php_version" ]]; then
        php_version="8.2"
    fi
    
    log_info "Installation de l'extension PHP $extension pour PHP $php_version..."
    
    # Installation de l'extension
    if apt install -y php$php_version-$extension; then
        log_info "Extension $extension installée avec succès"
        
        # Redémarrage de PHP-FPM
        systemctl restart php$php_version-fpm
        
        log_info "PHP-FPM redémarré"
        return 0
    else
        log_error "Échec de l'installation de l'extension $extension"
        return 1
    fi
}

# Vérifier la version de PHP
check_php_version() {
    local php_version=$1
    
    # Validation de la version
    if [[ -z "$php_version" ]]; then
        php_version="8.2"
    fi
    
    log_info "Vérification de la version de PHP..."
    
    # Vérification de l'installation
    if ! command -v php$php_version >/dev/null 2>&1; then
        log_error "PHP $php_version n'est pas installé"
        return 1
    fi
    
    # Affichage des informations
    echo -e "${BLUE}=== Informations PHP $php_version ===${NC}"
    php$php_version -v
    echo
    php$php_version -m
    
    return 0
}

# Optimiser les performances PHP
optimize_php() {
    local php_version=$1
    
    # Validation de la version
    if [[ -z "$php_version" ]]; then
        php_version="8.2"
    fi
    
    log_info "Optimisation des performances de PHP $php_version..."
    
    # Sauvegarde de la configuration
    backup_file "/etc/php/$php_version/fpm/php.ini"
    
    # Optimisation de la configuration
    sed -i 's/^memory_limit = .*/memory_limit = 256M/' "/etc/php/$php_version/fpm/php.ini"
    sed -i 's/^max_execution_time = .*/max_execution_time = 300/' "/etc/php/$php_version/fpm/php.ini"
    sed -i 's/^opcache.enable = .*/opcache.enable = 1/' "/etc/php/$php_version/fpm/php.ini"
    sed -i 's/^opcache.memory_consumption = .*/opcache.memory_consumption = 128/' "/etc/php/$php_version/fpm/php.ini"
    sed -i 's/^opcache.interned_strings_buffer = .*/opcache.interned_strings_buffer = 8/' "/etc/php/$php_version/fpm/php.ini"
    sed -i 's/^opcache.max_accelerated_files = .*/opcache.max_accelerated_files = 4000/' "/etc/php/$php_version/fpm/php.ini"
    sed -i 's/^opcache.revalidate_freq = .*/opcache.revalidate_freq = 60/' "/etc/php/$php_version/fpm/php.ini"
    sed -i 's/^opcache.fast_shutdown = .*/opcache.fast_shutdown = 1/' "/etc/php/$php_version/fpm/php.ini"
    
    # Redémarrage de PHP-FPM
    systemctl restart php$php_version-fpm
    
    log_info "Optimisation de PHP $php_version terminée"
    return 0
} 