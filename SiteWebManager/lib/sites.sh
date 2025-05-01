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
        show_error "Nom de domaine manquant"
        echo -e "${CYAN}Appuyez sur Entrée pour continuer...${NC}"
        read -p ""
        return 1
    fi
    
    show_info "Suppression du site $domain..."
    
    local status_ok=true
    
    # Désactivation du site
    if [[ -f "$APACHE_ENABLED/$domain.conf" ]]; then
        show_info "Désactivation du site..."
        if a2dissite "$domain.conf"; then
            show_success "Site désactivé avec succès"
        else
            show_error "Erreur lors de la désactivation du site"
            status_ok=false
        fi
    else
        show_warning "Le site n'était pas activé dans Apache"
    fi
    
    # Suppression de la configuration
    if [[ -f "$APACHE_AVAILABLE/$domain.conf" ]]; then
        show_info "Suppression de la configuration..."
        if rm "$APACHE_AVAILABLE/$domain.conf"; then
            show_success "Configuration supprimée avec succès"
        else
            show_error "Erreur lors de la suppression de la configuration"
            status_ok=false
        fi
    else
        show_warning "Aucun fichier de configuration trouvé pour ce domaine"
    fi
    
    # Suppression des fichiers du site
    if [[ -d "$WWW_DIR/$domain" ]]; then
        show_info "Suppression des fichiers du site..."
        local file_count=$(find "$WWW_DIR/$domain" -type f | wc -l)
        show_warning "Suppression de $file_count fichiers du répertoire $WWW_DIR/$domain"
        
        if rm -rf "$WWW_DIR/$domain"; then
            show_success "Fichiers supprimés avec succès"
        else
            show_error "Erreur lors de la suppression des fichiers"
            status_ok=false
        fi
    else
        show_warning "Aucun répertoire de site trouvé pour ce domaine"
    fi
    
    # Redémarrage d'Apache
    show_info "Redémarrage d'Apache..."
    if systemctl restart apache2; then
        show_success "Apache redémarré avec succès"
    else
        show_error "Erreur lors du redémarrage d'Apache"
        status_ok=false
    fi
    
    # Résumé
    echo
    if [[ "$status_ok" == true ]]; then
        show_success "Site $domain supprimé avec succès"
    else
        show_warning "La suppression du site $domain a rencontré des problèmes"
        echo -e "${YELLOW}Vérifiez les messages d'erreur ci-dessus et consultez les logs pour plus de détails${NC}"
    fi
    
    echo -e "${CYAN}Appuyez sur Entrée pour continuer...${NC}"
    read -p ""
    
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
        show_error "Nom de domaine manquant"
        echo -e "${CYAN}Appuyez sur Entrée pour continuer...${NC}"
        read -p ""
        return 1
    fi
    
    show_info "Réparation du site $domain..."
    echo
    
    local status_ok=true
    local actions_done=0
    
    echo -e "${BLUE}=== Réparation du site $domain ===${NC}"
    
    # Vérification du répertoire
    echo -e "${YELLOW}Étape 1: Vérification du répertoire${NC}"
    if [[ ! -d "$WWW_DIR/$domain" ]]; then
        show_warning "Le répertoire du site n'existe pas, création en cours..."
        if mkdir -p "$WWW_DIR/$domain"; then
            show_success "Répertoire $WWW_DIR/$domain créé avec succès"
            ((actions_done++))
        else
            show_error "Impossible de créer le répertoire du site"
            status_ok=false
        fi
    else
        show_success "Le répertoire du site existe déjà"
    fi
    
    echo
    
    # Création d'un fichier index par défaut si le répertoire est vide
    if [[ -d "$WWW_DIR/$domain" ]]; then
        local file_count=$(find "$WWW_DIR/$domain" -type f | wc -l)
        
        if [[ $file_count -eq 0 ]]; then
            show_warning "Le répertoire du site est vide, création d'un fichier index par défaut..."
            
            cat > "$WWW_DIR/$domain/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$domain - Site Web</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
            text-align: center;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            border: 1px solid #ddd;
            border-radius: 5px;
            background-color: #f9f9f9;
        }
        h1 {
            color: #2c3e50;
        }
        footer {
            margin-top: 30px;
            font-size: 0.8em;
            color: #777;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Bienvenue sur $domain</h1>
        <p>Ce site est en cours de construction.</p>
        <p>Cette page a été générée automatiquement par SiteWeb Manager.</p>
    </div>
    <footer>
        <p>Géré par SiteWeb Manager - $(date +"%d/%m/%Y")</p>
    </footer>
</body>
</html>
EOF
            
            show_success "Fichier index.html créé avec succès"
            ((actions_done++))
        else
            show_success "Le répertoire contient déjà des fichiers ($file_count fichiers trouvés)"
        fi
    fi
    
    echo
    
    # Correction des permissions
    echo -e "${YELLOW}Étape 2: Correction des permissions${NC}"
    show_info "Modification des propriétaires et des permissions..."
    
    if chown -R "$DEFAULT_OWNER" "$WWW_DIR/$domain"; then
        show_success "Propriétaire modifié avec succès"
        ((actions_done++))
    else
        show_error "Échec de la modification du propriétaire"
        status_ok=false
    fi
    
    if find "$WWW_DIR/$domain" -type d -exec chmod "$DEFAULT_PERMISSIONS" {} \; ; then
        show_success "Permissions des répertoires modifiées avec succès"
        ((actions_done++))
    else
        show_error "Échec de la modification des permissions des répertoires"
        status_ok=false
    fi
    
    if find "$WWW_DIR/$domain" -type f -exec chmod 644 {} \; ; then
        show_success "Permissions des fichiers modifiées avec succès"
        ((actions_done++))
    else
        show_error "Échec de la modification des permissions des fichiers"
        status_ok=false
    fi
    
    echo
    
    # Vérification de la configuration
    echo -e "${YELLOW}Étape 3: Configuration Apache${NC}"
    if [[ ! -f "$APACHE_AVAILABLE/$domain.conf" ]]; then
        show_warning "Le fichier de configuration Apache n'existe pas, création en cours..."
        
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
        
        show_success "Configuration Apache créée avec succès"
        ((actions_done++))
    else
        show_success "Le fichier de configuration Apache existe déjà"
    fi
    
    echo
    
    # Activation du site
    echo -e "${YELLOW}Étape 4: Activation du site${NC}"
    if [[ ! -f "$APACHE_ENABLED/$domain.conf" ]]; then
        show_warning "Le site n'est pas activé, activation en cours..."
        if a2ensite "$domain.conf"; then
            show_success "Site activé avec succès"
            ((actions_done++))
        else
            show_error "Échec de l'activation du site"
            status_ok=false
        fi
    else
        show_success "Le site est déjà activé"
    fi
    
    echo
    
    # Redémarrage d'Apache
    echo -e "${YELLOW}Étape 5: Redémarrage d'Apache${NC}"
    show_info "Redémarrage du service Apache..."
    if systemctl restart apache2; then
        show_success "Apache redémarré avec succès"
        ((actions_done++))
    else
        show_error "Échec du redémarrage d'Apache"
        status_ok=false
    fi
    
    echo
    
    # Résumé
    echo -e "${BLUE}=== Résumé de la réparation ===${NC}"
    if [[ "$status_ok" == true ]]; then
        if [[ $actions_done -gt 0 ]]; then
            show_success "Site $domain réparé avec succès ($actions_done actions effectuées)"
        else
            show_success "Aucune réparation nécessaire, le site $domain semble fonctionnel"
        fi
        
        echo -e "${YELLOW}URL du site:${NC} http://$domain"
        echo -e "${YELLOW}Répertoire:${NC} $WWW_DIR/$domain"
        echo -e "${YELLOW}Configuration:${NC} $APACHE_AVAILABLE/$domain.conf"
    else
        show_warning "La réparation du site $domain a rencontré des problèmes"
        echo -e "${YELLOW}Vérifiez les messages d'erreur ci-dessus et consultez les logs pour plus de détails${NC}"
    fi
    
    echo -e "\n${CYAN}Appuyez sur Entrée pour revenir au menu...${NC}"
    read -p ""
    
    return 0
}

# Fonction pour scanner le système à la recherche de sites potentiels
scan_potential_sites() {
    local search_dir=$1
    local deployment_mode=$2
    
    # Validation du répertoire de recherche
    if [[ -z "$search_dir" ]]; then
        search_dir="/home"
    fi
    
    show_info "Recherche de sites potentiels dans $search_dir..."
    echo
    
    echo -e "${BLUE}=== Sites potentiels ===${NC}"
    echo -e "${YELLOW}Recherche de dossiers contenant des fichiers index.html ou index.php...${NC}"
    echo -e "${CYAN}Cela peut prendre un moment selon le nombre de fichiers...${NC}"
    echo
    
    # Tableau pour stocker les résultats
    declare -a potential_sites
    local count=0
    
    # Recherche des dossiers contenant index.html
    echo -e "${YELLOW}Recherche des fichiers index.html...${NC}"
    while IFS= read -r file; do
        local dir=$(dirname "$file")
        potential_sites+=("$dir")
        ((count++))
    done < <(find "$search_dir" -name "index.html" -type f 2>/dev/null)
    
    # Recherche des dossiers contenant index.php
    echo -e "${YELLOW}Recherche des fichiers index.php...${NC}"
    while IFS= read -r file; do
        local dir=$(dirname "$file")
        # Vérifier si ce dossier n'est pas déjà dans la liste (avec index.html)
        if ! echo "${potential_sites[@]}" | grep -q "$dir"; then
            potential_sites+=("$dir")
            ((count++))
        fi
    done < <(find "$search_dir" -name "index.php" -type f 2>/dev/null)
    
    # Afficher les résultats
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}Aucun site potentiel trouvé.${NC}"
        echo
        echo -e "${CYAN}Appuyez sur Entrée pour revenir au menu...${NC}"
        read -p ""
        return 1
    else
        echo -e "${GREEN}$count sites potentiels trouvés :${NC}"
        echo
        
        # Afficher les résultats numérotés
        for ((i=0; i<${#potential_sites[@]}; i++)); do
            echo -e "${GREEN}$((i+1)).${NC} ${potential_sites[$i]}"
        done
        
        echo
        
        if [[ "$deployment_mode" == "select" ]]; then
            echo -e "${YELLOW}Sélectionnez un site par son numéro (1-$count) ou 0 pour annuler :${NC}"
            local choice
            read -p "Votre choix : " choice
            
            if [[ "$choice" =~ ^[0-9]+$ ]]; then
                if [[ "$choice" -ge 1 && "$choice" -le $count ]]; then
                    # Retourner le chemin du site sélectionné
                    echo "${potential_sites[$((choice-1))]}"
                    return 0
                elif [[ "$choice" -eq 0 ]]; then
                    echo "cancel"
                    return 2
                else
                    show_error "Choix invalide."
                    echo
                    echo -e "${CYAN}Appuyez sur Entrée pour revenir au menu...${NC}"
                    read -p ""
                    return 1
                fi
            else
                show_error "Veuillez entrer un nombre."
                echo
                echo -e "${CYAN}Appuyez sur Entrée pour revenir au menu...${NC}"
                read -p ""
                return 1
            fi
        else
            echo -e "${CYAN}Pour déployer un de ces sites, notez son numéro pour le sélectionner ultérieurement.${NC}"
            echo
            echo -e "${CYAN}Appuyez sur Entrée pour revenir au menu...${NC}"
            read -p ""
            return 0
        fi
    fi
}

# Fonction pour obtenir la liste des sites déployés avec sélection
list_deployed_sites_with_selection() {
    echo -e "${BLUE}=== Sites déployés ===${NC}"
    
    # Tableau pour stocker les sites déployés
    declare -a deployed_sites
    local count=0
    
    # Lister les sites déployés
    while IFS= read -r site; do
        if [[ "$site" != "html" ]]; then
            deployed_sites+=("$site")
            echo -e "${GREEN}$((count+1)).${NC} $site"
            ((count++))
        fi
    done < <(ls -1 "$WWW_DIR" 2>/dev/null)
    
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}Aucun site déployé.${NC}"
        echo
        echo -e "${CYAN}Appuyez sur Entrée pour revenir au menu...${NC}"
        read -p ""
        return 1
    fi
    
    echo
    echo -e "${YELLOW}Sélectionnez un site par son numéro (1-$count) ou 0 pour annuler :${NC}"
    local choice
    read -p "Votre choix : " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        if [[ "$choice" -ge 1 && "$choice" -le $count ]]; then
            # Retourner le nom du site sélectionné
            echo "${deployed_sites[$((choice-1))]}"
            return 0
        elif [[ "$choice" -eq 0 ]]; then
            echo "cancel"
            return 2
        else
            show_error "Choix invalide."
            return 1
        fi
    else
        show_error "Veuillez entrer un nombre."
        return 1
    fi
} 