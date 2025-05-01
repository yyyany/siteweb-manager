#!/bin/bash
# Fonctions de gestion des sites web

# Fonction pour déployer un site web
deploy_site() {
    local source_dir=$1
    local domain=$2
    
    # Validation des paramètres avec messages clairs
    if [[ -z "$source_dir" || -z "$domain" ]]; then
        show_error "Paramètres manquants pour le déploiement du site"
        echo -e "${YELLOW}Usage: Veuillez spécifier le chemin source et le nom de domaine${NC}"
        echo -e "${CYAN}Appuyez sur Entrée pour continuer...${NC}"
        read -p ""
        return 1
    fi
    
    # Validation du domaine avec explication
    if ! validate_domain "$domain"; then
        show_error "Nom de domaine invalide: $domain"
        echo -e "${YELLOW}Un nom de domaine valide doit être au format exemple.com${NC}"
        echo -e "${CYAN}Appuyez sur Entrée pour continuer...${NC}"
        read -p ""
        return 1
    fi
    
    # Vérification du répertoire source avec suggestion
    if [[ ! -d "$source_dir" ]]; then
        show_error "Le répertoire source n'existe pas: $source_dir"
        echo -e "${YELLOW}Conseil: Vérifiez le chemin et assurez-vous que le répertoire existe${NC}"
        echo -e "${YELLOW}Exemple de chemin valide: /home/utilisateur/mon-site${NC}"
        echo -e "${CYAN}Appuyez sur Entrée pour continuer...${NC}"
        read -p ""
        return 1
    fi
    
    # Vérification si le site existe déjà
    if [[ -d "$WWW_DIR/$domain" ]]; then
        show_warning "Un site avec ce nom de domaine existe déjà: $domain"
        echo -e "${YELLOW}Options: Vous pouvez soit supprimer le site existant, soit utiliser un autre nom de domaine${NC}"
        
        if ! show_confirm "Voulez-vous remplacer le site existant?" "n"; then
            echo -e "${CYAN}Déploiement annulé par l'utilisateur.${NC}"
            echo -e "${CYAN}Appuyez sur Entrée pour continuer...${NC}"
            read -p ""
            return 1
        fi
    fi
    
    echo -e "${BLUE}=== Déploiement du site $domain ===${NC}"
    echo -e "${YELLOW}Source:${NC} $source_dir"
    echo -e "${YELLOW}Destination:${NC} $WWW_DIR/$domain"
    
    # Création du répertoire du site avec progression
    show_info "Création du répertoire du site..."
    mkdir -p "$WWW_DIR/$domain"
    
    # Copie des fichiers avec indication visuelle
    show_info "Copie des fichiers en cours..."
    echo -e "${CYAN}Cela peut prendre un moment selon la taille du site...${NC}"
    cp -r "$source_dir"/* "$WWW_DIR/$domain/" && show_success "Fichiers copiés avec succès" || { 
        show_error "Erreur lors de la copie des fichiers"; 
        echo -e "${CYAN}Appuyez sur Entrée pour continuer...${NC}";
        read -p "";
        return 1; 
    }
    
    # Configuration des permissions
    show_info "Configuration des permissions..."
    chown -R "$DEFAULT_OWNER" "$WWW_DIR/$domain" && show_success "Permissions configurées" || show_warning "Problème lors de la configuration des permissions"
    find "$WWW_DIR/$domain" -type d -exec chmod "$DEFAULT_PERMISSIONS" {} \;
    find "$WWW_DIR/$domain" -type f -exec chmod 644 {} \;
    
    # Création de la configuration Apache
    show_info "Création de la configuration Apache..."
    local config_file="$APACHE_AVAILABLE/$domain.conf"
    
    cat > "$config_file" << EOF
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
    
    # Activation du site avec feedback
    show_info "Activation du site..."
    if a2ensite "$domain.conf"; then
        show_success "Site activé avec succès"
    else
        show_error "Erreur lors de l'activation du site"
        echo -e "${YELLOW}Conseil: Vérifiez la configuration Apache${NC}"
        echo -e "${CYAN}Appuyez sur Entrée pour continuer...${NC}"
        read -p ""
        return 1
    fi
    
    # Redémarrage d'Apache avec feedback
    show_info "Redémarrage d'Apache..."
    if systemctl restart apache2; then
        show_success "Apache redémarré avec succès"
    else
        show_error "Erreur lors du redémarrage d'Apache"
        echo -e "${YELLOW}Le site a été configuré mais Apache n'a pas pu redémarrer.${NC}"
        echo -e "${YELLOW}Conseil: Vérifiez les logs Apache pour plus d'informations: /var/log/apache2/error.log${NC}"
    fi
    
    show_success "Site $domain déployé avec succès!"
    echo -e "${YELLOW}URL du site:${NC} http://$domain"
    echo -e "${YELLOW}Répertoire du site:${NC} $WWW_DIR/$domain"
    echo -e "${YELLOW}Fichier de configuration:${NC} $config_file"
    echo -e "${YELLOW}Note:${NC} N'oubliez pas de configurer votre DNS pour pointer vers votre serveur"
    
    echo -e "\n${CYAN}Appuyez sur Entrée pour revenir au menu...${NC}"
    read -p ""
    
    return 0
}

# Fonction pour lister les sites web
list_sites() {
    log_info "Liste des sites web..."
    
    echo -e "${BLUE}=== Sites web ===${NC}"
    
    # Sites disponibles
    echo -e "\n${YELLOW}Sites disponibles :${NC}"
    ls -1 "$APACHE_AVAILABLE" | grep -v "000-default.conf" | sed 's/\.conf$//' || echo "Aucun site disponible"
    
    # Sites activés
    echo -e "\n${YELLOW}Sites activés :${NC}"
    ls -1 "$APACHE_ENABLED" | grep -v "000-default.conf" | sed 's/\.conf$//' || echo "Aucun site activé"
    
    # Sites déployés
    echo -e "\n${YELLOW}Sites déployés :${NC}"
    ls -1 "$WWW_DIR" | grep -v "html" || echo "Aucun site déployé"
    
    # Ajout d'une pause pour que l'utilisateur puisse lire les informations
    echo -e "\n${CYAN}Appuyez sur Entrée pour revenir au menu...${NC}"
    read -p ""
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
        show_error "Nom de domaine manquant"
        return 1
    fi
    
    show_info "Vérification du site $domain..."
    echo
    
    local status_ok=true
    
    # Vérification du répertoire
    echo -e "${BLUE}=== Vérification du répertoire ===${NC}"
    if [[ -d "$WWW_DIR/$domain" ]]; then
        show_success "Le répertoire du site existe: $WWW_DIR/$domain"
        
        # Vérifier s'il contient des fichiers
        local file_count=$(find "$WWW_DIR/$domain" -type f | wc -l)
        if [[ $file_count -eq 0 ]]; then
            show_warning "Le répertoire est vide. Aucun fichier trouvé."
            status_ok=false
        else
            show_success "Nombre de fichiers trouvés: $file_count"
            
            # Vérification du fichier index
            if [[ -f "$WWW_DIR/$domain/index.html" || -f "$WWW_DIR/$domain/index.php" ]]; then
                show_success "Fichier index trouvé"
            else
                show_warning "Aucun fichier index.html ou index.php trouvé. Le site pourrait ne pas s'afficher correctement."
                status_ok=false
            fi
        fi
    else
        show_error "Le répertoire du site n'existe pas: $WWW_DIR/$domain"
        echo -e "${YELLOW}Conseil:${NC} Utilisez l'option 'Réparer un site' ou 'Déployer un site'"
        status_ok=false
    fi
    
    echo
    
    # Vérification de la configuration Apache
    echo -e "${BLUE}=== Vérification de la configuration Apache ===${NC}"
    if [[ -f "$APACHE_AVAILABLE/$domain.conf" ]]; then
        show_success "Le fichier de configuration existe: $APACHE_AVAILABLE/$domain.conf"
        
        # Vérification du contenu de la configuration
        if grep -q "ServerName $domain" "$APACHE_AVAILABLE/$domain.conf"; then
            show_success "La directive ServerName est correctement configurée"
        else
            show_warning "La directive ServerName n'est pas correctement configurée"
            status_ok=false
        fi
        
        if grep -q "DocumentRoot $WWW_DIR/$domain" "$APACHE_AVAILABLE/$domain.conf"; then
            show_success "La directive DocumentRoot est correctement configurée"
        else
            show_warning "Le DocumentRoot n'est pas correctement configuré"
            status_ok=false
        fi
    else
        show_error "Le fichier de configuration Apache n'existe pas"
        echo -e "${YELLOW}Conseil:${NC} Utilisez l'option 'Réparer un site'"
        status_ok=false
    fi
    
    echo
    
    # Vérification de l'activation du site
    echo -e "${BLUE}=== Vérification de l'activation du site ===${NC}"
    if [[ -f "$APACHE_ENABLED/$domain.conf" ]]; then
        show_success "Le site est activé"
    else
        show_error "Le site n'est pas activé"
        echo -e "${YELLOW}Conseil:${NC} Activez le site avec la commande a2ensite $domain.conf"
        status_ok=false
    fi
    
    echo
    
    # Vérification des permissions
    echo -e "${BLUE}=== Vérification des permissions ===${NC}"
    if [[ -d "$WWW_DIR/$domain" ]]; then
        local owner=$(stat -c "%U:%G" "$WWW_DIR/$domain")
        if [[ "$owner" == "$DEFAULT_OWNER" ]]; then
            show_success "Le propriétaire du site est correct: $owner"
        else
            show_warning "Le propriétaire du site n'est pas correct: $owner (attendu: $DEFAULT_OWNER)"
            echo -e "${YELLOW}Conseil:${NC} Utilisez l'option 'Réparer un site' pour corriger les permissions"
            status_ok=false
        fi
        
        # Vérification des permissions des répertoires
        local dir_perm=$(stat -c "%a" "$WWW_DIR/$domain")
        if [[ "$dir_perm" == "$DEFAULT_PERMISSIONS" ]]; then
            show_success "Les permissions du répertoire principal sont correctes: $dir_perm"
        else
            show_warning "Les permissions du répertoire principal ne sont pas correctes: $dir_perm (attendu: $DEFAULT_PERMISSIONS)"
            status_ok=false
        fi
    fi
    
    echo
    
    # Vérification de l'état d'Apache
    echo -e "${BLUE}=== Vérification du service Apache ===${NC}"
    if systemctl is-active --quiet apache2; then
        show_success "Le service Apache est actif"
    else
        show_error "Le service Apache n'est pas actif"
        echo -e "${YELLOW}Conseil:${NC} Démarrez Apache avec la commande: systemctl start apache2"
        status_ok=false
    fi
    
    echo
    
    # Résumé
    echo -e "${BLUE}=== Résumé de la vérification ===${NC}"
    if [[ "$status_ok" == true ]]; then
        show_success "Le site $domain est correctement configuré et semble fonctionnel"
        echo -e "${YELLOW}URL:${NC} http://$domain"
        echo -e "${YELLOW}Répertoire:${NC} $WWW_DIR/$domain"
        echo -e "${YELLOW}Configuration:${NC} $APACHE_AVAILABLE/$domain.conf"
    else
        show_warning "Le site $domain présente des problèmes qui doivent être corrigés"
        echo -e "${YELLOW}Conseil:${NC} Utilisez l'option 'Réparer un site' pour tenter de résoudre les problèmes"
    fi
    
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