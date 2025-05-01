#!/bin/bash
# Fonctions de gestion des sites web

# Fonction pour déployer un site web
deploy_site() {
    local source_dir=$1
    local domain=$2
    
    # Validation des paramètres
    if [[ -z "$source_dir" || -z "$domain" ]]; then
        log_error "Paramètres manquants pour le déploiement du site"
        return 1
    fi
    
    # Validation du domaine
    if ! validate_domain "$domain"; then
        log_error "Nom de domaine invalide: $domain"
        return 1
    fi
    
    # Vérification du répertoire source
    if [[ ! -d "$source_dir" ]]; then
        log_error "Le répertoire source n'existe pas: $source_dir"
        return 1
    fi
    
    log_info "Déploiement du site $domain..."
    
    # Création du répertoire du site
    local site_dir="$WWW_DIR/$domain"
    mkdir -p "$site_dir"
    
    # Copie des fichiers
    log_info "Copie des fichiers..."
    cp -r "$source_dir"/* "$site_dir/"
    
    # Configuration des permissions
    log_info "Configuration des permissions..."
    chown -R "$DEFAULT_OWNER" "$site_dir"
    find "$site_dir" -type d -exec chmod "$DEFAULT_PERMISSIONS" {} \;
    find "$site_dir" -type f -exec chmod 644 {} \;
    
    # Création de la configuration Apache
    log_info "Création de la configuration Apache..."
    local config_file="$APACHE_AVAILABLE/$domain.conf"
    
    cat > "$config_file" << EOF
<VirtualHost *:80>
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot $site_dir
    
    <Directory $site_dir>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/$domain-error.log
    CustomLog \${APACHE_LOG_DIR}/$domain-access.log combined
</VirtualHost>
EOF
    
    # Activation du site
    log_info "Activation du site..."
    a2ensite "$domain.conf"
    
    # Redémarrage d'Apache
    systemctl restart apache2
    
    log_info "Site $domain déployé avec succès"
    return 0
}

# Fonction pour lister les sites web
list_sites() {
    log_info "Liste des sites web..."
    
    echo -e "${BLUE}=== Sites web ===${NC}"
    
    # Sites disponibles
    echo -e "\n${YELLOW}Sites disponibles :${NC}"
    ls -1 "$APACHE_AVAILABLE" | grep -v "000-default.conf" | sed 's/\.conf$//'
    
    # Sites activés
    echo -e "\n${YELLOW}Sites activés :${NC}"
    ls -1 "$APACHE_ENABLED" | grep -v "000-default.conf" | sed 's/\.conf$//'
    
    # Sites déployés
    echo -e "\n${YELLOW}Sites déployés :${NC}"
    ls -1 "$WWW_DIR" | grep -v "html"
}

# Fonction pour supprimer un site web
remove_site() {
    local domain=$1
    
    # Validation du domaine
    if [[ -z "$domain" ]]; then
        log_error "Nom de domaine manquant"
        return 1
    fi
    
    log_info "Suppression du site $domain..."
    
    # Désactivation du site
    if [[ -f "$APACHE_ENABLED/$domain.conf" ]]; then
        log_info "Désactivation du site..."
        a2dissite "$domain.conf"
    fi
    
    # Suppression de la configuration
    if [[ -f "$APACHE_AVAILABLE/$domain.conf" ]]; then
        log_info "Suppression de la configuration..."
        rm "$APACHE_AVAILABLE/$domain.conf"
    fi
    
    # Suppression des fichiers du site
    if [[ -d "$WWW_DIR/$domain" ]]; then
        log_info "Suppression des fichiers..."
        rm -rf "$WWW_DIR/$domain"
    fi
    
    # Redémarrage d'Apache
    systemctl restart apache2
    
    log_info "Site $domain supprimé avec succès"
    return 0
}

# Fonction pour vérifier un site web
check_site() {
    local domain=$1
    
    # Validation du domaine
    if [[ -z "$domain" ]]; then
        log_error "Nom de domaine manquant"
        return 1
    fi
    
    log_info "Vérification du site $domain..."
    
    # Vérification du répertoire
    if [[ ! -d "$WWW_DIR/$domain" ]]; then
        log_error "Le répertoire du site n'existe pas"
        return 1
    fi
    
    # Vérification de la configuration
    if [[ ! -f "$APACHE_AVAILABLE/$domain.conf" ]]; then
        log_error "La configuration Apache n'existe pas"
        return 1
    fi
    
    # Vérification de l'activation
    if [[ ! -f "$APACHE_ENABLED/$domain.conf" ]]; then
        log_error "Le site n'est pas activé"
        return 1
    fi
    
    # Vérification des permissions
    local owner=$(stat -c "%U:%G" "$WWW_DIR/$domain")
    if [[ "$owner" != "$DEFAULT_OWNER" ]]; then
        log_warning "Le propriétaire du site n'est pas correct: $owner"
    fi
    
    log_info "Site $domain vérifié avec succès"
    return 0
}

# Fonction pour réparer un site web
repair_site() {
    local domain=$1
    
    # Validation du domaine
    if [[ -z "$domain" ]]; then
        log_error "Nom de domaine manquant"
        return 1
    fi
    
    log_info "Réparation du site $domain..."
    
    # Vérification du répertoire
    if [[ ! -d "$WWW_DIR/$domain" ]]; then
        log_info "Création du répertoire du site..."
        mkdir -p "$WWW_DIR/$domain"
    fi
    
    # Correction des permissions
    log_info "Correction des permissions..."
    chown -R "$DEFAULT_OWNER" "$WWW_DIR/$domain"
    find "$WWW_DIR/$domain" -type d -exec chmod "$DEFAULT_PERMISSIONS" {} \;
    find "$WWW_DIR/$domain" -type f -exec chmod 644 {} \;
    
    # Vérification de la configuration
    if [[ ! -f "$APACHE_AVAILABLE/$domain.conf" ]]; then
        log_info "Création de la configuration Apache..."
        cat > "$APACHE_AVAILABLE/$domain.conf" << EOF
<VirtualHost *:80>
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot $WWW_DIR/$domain
    
    <Directory $WWW_DIR/$domain>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/$domain-error.log
    CustomLog \${APACHE_LOG_DIR}/$domain-access.log combined
</VirtualHost>
EOF
    fi
    
    # Activation du site
    if [[ ! -f "$APACHE_ENABLED/$domain.conf" ]]; then
        log_info "Activation du site..."
        a2ensite "$domain.conf"
    fi
    
    # Redémarrage d'Apache
    systemctl restart apache2
    
    log_info "Site $domain réparé avec succès"
    return 0
} 