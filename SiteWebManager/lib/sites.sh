#!/bin/bash
# Fonctions de gestion des sites web

# Fonction pour déployer un nouveau site
deploy_site() {
    log_info "Déploiement d'un nouveau site web..."
    
    # Étape 1: Demander le nom du site (qui servira aussi de nom de dossier)
    local site_name=$(get_user_input "Entrez le nom du site (sera utilisé comme nom de dossier)" "" true)
    site_name=$(echo "$site_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    
    if [ -z "$site_name" ]; then
        show_error "Le nom du site ne peut pas être vide"
        return 1
    fi
    
    # Étape 2: Demander le nom de domaine
    local domain=$(get_user_input "Entrez le nom de domaine (ex: example.com)" "" true)
    domain=$(echo "$domain" | tr '[:upper:]' '[:lower:]')
    
    if ! validate_domain "$domain"; then
        show_error "Nom de domaine invalide: $domain"
        return 1
    fi
    
    # Étape 3: Demander l'adresse IP publique du serveur
    local detected_ip=$(get_server_ip)
    local server_ip=$(get_user_input "Entrez l'adresse IP publique du serveur" "$detected_ip" true)
    
    if ! [[ $server_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        show_error "Format d'adresse IP invalide: $server_ip"
        if ! confirm_action "Voulez-vous continuer quand même?"; then
            return 1
        fi
    fi
    
    # Étape 4: Vérifier si l'utilisateur veut spécifier un dossier source
    local source_dir=""
    if confirm_action "Voulez-vous déployer un site existant depuis un dossier local?"; then
        source_dir=$(get_user_input "Entrez le chemin complet du dossier source contenant le site" "" true)
        
        if [ ! -d "$source_dir" ]; then
            show_error "Le dossier source n'existe pas: $source_dir"
            return 1
        fi
    fi
    
    # Vérifier si le site existe déjà
    if [ -d "$WWW_DIR/$site_name" ]; then
        show_warning "Le répertoire du site existe déjà: $WWW_DIR/$site_name"
        
        if ! confirm_action "Voulez-vous continuer et écraser le contenu existant?"; then
            return 1
        fi
    fi
    
    if [ -f "$APACHE_AVAILABLE/$domain.conf" ]; then
        show_warning "La configuration Apache existe déjà: $APACHE_AVAILABLE/$domain.conf"
        
        if ! confirm_action "Voulez-vous continuer et écraser la configuration existante?"; then
            return 1
        fi
    fi
    
    # Étape 5: Créer le répertoire du site
    log_info "Création du répertoire pour le site: $WWW_DIR/$site_name"
    
    if [ -d "$WWW_DIR/$site_name" ]; then
        backup_dir "$WWW_DIR/$site_name"
        rm -rf "$WWW_DIR/$site_name"
    fi
    
    mkdir -p "$WWW_DIR/$site_name"
    
    # Étape 6: Si un dossier source est spécifié, copier son contenu
    if [ -n "$source_dir" ]; then
        log_info "Copie des fichiers depuis $source_dir vers $WWW_DIR/$site_name..."
        cp -r "$source_dir"/* "$WWW_DIR/$site_name"/ 2>/dev/null
        if [ $? -ne 0 ]; then
            show_warning "Certains fichiers n'ont pas pu être copiés. Vérifiez les permissions."
        fi
    # Sinon, créer la page d'accueil par défaut
    elif [ "$CREATE_DEFAULT_INDEX" = true ]; then
        log_info "Création de la page d'accueil par défaut..."
        generate_default_index "$WWW_DIR/$site_name" "$domain" "nouveau"
    fi
    
    # Étape 7: Créer la configuration Apache
    log_info "Création de la configuration Apache pour $domain..."
    
    cat > "$APACHE_AVAILABLE/$domain.conf" <<EOL
<VirtualHost *:$DEFAULT_HTTP_PORT>
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot $WWW_DIR/$site_name
    
    <Directory $WWW_DIR/$site_name>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/$domain-error.log
    CustomLog \${APACHE_LOG_DIR}/$domain-access.log combined
    
    # Configuration optimisée
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/x-javascript
    </IfModule>
    
    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType image/jpg "access plus 1 year"
        ExpiresByType image/jpeg "access plus 1 year"
        ExpiresByType image/gif "access plus 1 year"
        ExpiresByType image/png "access plus 1 year"
        ExpiresByType image/webp "access plus 1 year"
        ExpiresByType text/css "access plus 1 month"
        ExpiresByType application/pdf "access plus 1 month"
        ExpiresByType text/javascript "access plus 1 month"
        ExpiresByType application/javascript "access plus 1 month"
        ExpiresByType image/x-icon "access plus 1 year"
        ExpiresDefault "access plus 2 days"
    </IfModule>
</VirtualHost>
EOL
    
    # Étape 8: Activer le site
    log_info "Activation du site $domain..."
    a2ensite "$domain.conf" >/dev/null 2>&1
    
    # Étape 9: Redémarrer Apache
    log_info "Redémarrage d'Apache..."
    if ! restart_apache; then
        show_error "Échec du redémarrage d'Apache"
        return 1
    fi
    
    # Étape 10: Définir les permissions
    log_info "Configuration des permissions..."
    chown -R $DEFAULT_OWNER "$WWW_DIR/$site_name"
    chmod -R $DEFAULT_PERMISSIONS "$WWW_DIR/$site_name"
    find "$WWW_DIR/$site_name" -type f -exec chmod $DEFAULT_FILE_PERMISSIONS {} \;
    
    # Étape 11: Afficher les informations DNS
    show_success "Site $domain déployé avec succès"
    
    # Afficher les informations DNS avec l'IP spécifiée par l'utilisateur
    show_info "Pour que votre site soit accessible, configurez les DNS suivants:"
    echo -e "Type A: ${BOLD_YELLOW}$domain${NC}\t→\t${BOLD_CYAN}$server_ip${NC}"
    echo -e "Type A: ${BOLD_YELLOW}www.$domain${NC}\t→\t${BOLD_CYAN}$server_ip${NC}"
    
    # Étape 12: Proposer de configurer HTTPS
    if confirm_action "Voulez-vous configurer HTTPS pour ce site maintenant?"; then
        configure_https "$domain"
    else
        show_info "Vous pourrez configurer HTTPS plus tard via le menu SSL/HTTPS"
    fi
    
    # Étape 13: Indiquer comment accéder au site
    show_info "Votre site est accessible aux adresses suivantes:"
    echo -e "http://$domain:$DEFAULT_HTTP_PORT"
    echo -e "http://www.$domain:$DEFAULT_HTTP_PORT"
    
    if grep -q "SSLEngine on" "$APACHE_AVAILABLE/$domain.conf" || [ -f "$APACHE_AVAILABLE/$domain-le-ssl.conf" ]; then
        echo -e "https://$domain:$DEFAULT_HTTPS_PORT"
        echo -e "https://www.$domain:$DEFAULT_HTTPS_PORT"
    fi
    
    return 0
}

# Fonction pour lister les sites déployés
list_sites() {
    log_info "Liste des sites déployés..."
    
    # Vérifier si Apache est installé
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé"
        return 1
    fi
    
    show_header "Sites Web Déployés"
    
    # Compter les sites disponibles et activés
    local available_count=$(find "$APACHE_AVAILABLE" -type f -name "*.conf" ! -name "000-default.conf" ! -name "default-ssl.conf" | wc -l)
    local enabled_count=$(find "$APACHE_ENABLED" -type l -name "*.conf" ! -name "000-default.conf" ! -name "default-ssl.conf" | wc -l)
    
    show_info "Total: $available_count sites configurés, $enabled_count sites activés"
    echo ""
    
    # En-tête du tableau
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC} ${YELLOW}Nom du site${NC}      │ ${YELLOW}Document Root${NC}       │ ${YELLOW}Statut${NC}    │ ${YELLOW}HTTPS${NC}     │"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────────┤${NC}"
    
    # Parcourir les fichiers de configuration
    for conf_file in "$APACHE_AVAILABLE"/*.conf; do
        # Ignorer les fichiers par défaut
        filename=$(basename "$conf_file")
        if [ "$filename" = "000-default.conf" ] || [ "$filename" = "default-ssl.conf" ]; then
            continue
        fi
        
        # Extraire les informations
        local domain=${filename%.conf}
        local document_root=$(grep -i "DocumentRoot" "$conf_file" | awk '{print $2}' | head -1)
        
        # Vérifier si le site est activé
        if [ -L "$APACHE_ENABLED/$filename" ]; then
            local status="${GREEN}Activé${NC}"
        else
            local status="${RED}Désactivé${NC}"
        fi
        
        # Vérifier si HTTPS est configuré
        if grep -q -i "VirtualHost.*:443" "$conf_file" || [ -f "$APACHE_AVAILABLE/${domain}-le-ssl.conf" ]; then
            local https="${GREEN}Oui${NC}"
        else
            local https="${RED}Non${NC}"
        fi
        
        # Afficher les informations
        printf "${BLUE}│${NC} %-15s │ %-20s │ %-10s │ %-10s │\n" "$domain" "$document_root" "$status" "$https"
    done
    
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────────┘${NC}"
    
    return 0
}

# Fonction pour supprimer un site web
delete_site() {
    log_info "Suppression d'un site web..."
    
    # Vérifier si Apache est installé
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé"
        return 1
    fi
    
    show_header "Suppression d'un site web"
    
    # Récupérer la liste des sites disponibles (hors sites par défaut)
    local sites_list=()
    local i=1
    
    for conf_file in "$APACHE_AVAILABLE"/*.conf; do
        filename=$(basename "$conf_file")
        if [[ "$filename" != "000-default.conf" && "$filename" != "default-ssl.conf" ]]; then
            domain=${filename%.conf}
            if [ -L "$APACHE_ENABLED/$filename" ]; then
                status="${GREEN}(activé)${NC}"
            else
                status="${RED}(désactivé)${NC}"
            fi
            
            sites_list[$i]="$domain"
            echo -e "${YELLOW}[$i]${NC} $domain $status"
            ((i++))
        fi
    done
    
    # Vérifier si des sites sont disponibles
    if [ ${#sites_list[@]} -eq 0 ]; then
        show_info "Aucun site personnalisé n'a été trouvé."
        return 0
    fi
    
    echo -e "${RED}[0]${NC} Annuler"
    echo ""
    
    # Demander le site à supprimer
    local choice=$(get_user_choice "Sélectionnez le site à supprimer" $((${#sites_list[@]})))
    
    if [ "$choice" -eq 0 ]; then
        show_info "Suppression annulée"
        return 0
    fi
    
    if [ "$choice" -gt 0 ] && [ "$choice" -le "${#sites_list[@]}" ]; then
        local selected_domain="${sites_list[$choice]}"
        
        # Confirmation de la suppression
        show_warning "Vous êtes sur le point de supprimer le site $selected_domain et tous ses fichiers."
        if ! confirm_action "Êtes-vous sûr de vouloir continuer?"; then
            show_info "Suppression annulée"
            return 0
        fi
        
        # Sauvegarder avant la suppression
        if [ "$BACKUP_BEFORE_CHANGES" = true ]; then
            log_info "Sauvegarde du site avant suppression..."
            
            local date_suffix=$(date +'%Y%m%d_%H%M%S')
            local backup_dir="$BACKUP_DIR/websites"
            
            if [ ! -d "$backup_dir" ]; then
                mkdir -p "$backup_dir"
            fi
            
            # Déterminer le dossier du site à partir de la configuration
            local site_path=$(grep -i "DocumentRoot" "$APACHE_AVAILABLE/$selected_domain.conf" | awk '{print $2}' | head -1)
            
            if [ -d "$site_path" ]; then
                local backup_file="$backup_dir/${selected_domain}_$date_suffix.tar.gz"
                if tar -czf "$backup_file" "$site_path"; then
                    show_success "Site sauvegardé dans $backup_file"
                else
                    show_error "Échec de la sauvegarde du site"
                    if ! confirm_action "Continuer sans sauvegarde?"; then
                        return 1
                    fi
                fi
            fi
            
            # Sauvegarder la configuration Apache
            backup_file "$APACHE_AVAILABLE/$selected_domain.conf"
        fi
        
        # Désactiver le site s'il est activé
        if [ -L "$APACHE_ENABLED/$selected_domain.conf" ]; then
            log_info "Désactivation du site $selected_domain..."
            if ! a2dissite "$selected_domain.conf" > /dev/null 2>&1; then
                show_error "Échec de la désactivation du site"
            fi
        fi
        
        # Supprimer la configuration du site
        log_info "Suppression de la configuration Apache..."
        if ! rm -f "$APACHE_AVAILABLE/$selected_domain.conf"; then
            show_error "Échec de la suppression de la configuration"
        fi
        
        # Supprimer la configuration SSL si elle existe
        if [ -f "$APACHE_AVAILABLE/$selected_domain-le-ssl.conf" ]; then
            log_info "Suppression de la configuration SSL..."
            rm -f "$APACHE_AVAILABLE/$selected_domain-le-ssl.conf"
        fi
        
        # Supprimer les fichiers du site
        local site_path=$(grep -i "DocumentRoot" "$APACHE_AVAILABLE/$selected_domain.conf" 2>/dev/null | awk '{print $2}' | head -1)
        
        if [ -n "$site_path" ] && [ -d "$site_path" ]; then
            log_info "Suppression des fichiers du site..."
            if confirm_action "Voulez-vous supprimer le dossier $site_path et tout son contenu?"; then
                if ! rm -rf "$site_path"; then
                    show_error "Échec de la suppression des fichiers"
                else
                    show_success "Dossier $site_path supprimé"
                fi
            else
                show_info "Les fichiers du site ont été conservés"
            fi
        fi
        
        # Redémarrer Apache
        log_info "Redémarrage d'Apache..."
        if ! restart_apache; then
            show_error "Échec du redémarrage d'Apache"
        fi
        
        show_success "Site $selected_domain supprimé avec succès"
    else
        show_error "Choix invalide"
    fi
    
    return 0
}

# Fonction pour vérifier et réparer un site
check_repair_site() {
    log_info "Vérification et réparation d'un site..."
    
    # Vérifier si Apache est installé
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé"
        return 1
    fi
    
    show_header "Vérification et Réparation de Site"
    
    # Obtenir le nom de domaine à vérifier
    local domain_name=$(get_user_input "Entrez le nom de domaine à vérifier/réparer" "" true)
    
    # Valider le nom de domaine
    if ! validate_domain "$domain_name"; then
        show_error "Nom de domaine invalide: $domain_name"
        return 1
    fi
    
    # Vérification de la configuration Apache
    echo -e "\n${YELLOW}Vérification de la configuration Apache...${NC}"
    
    if [ -f "$APACHE_AVAILABLE/$domain_name.conf" ]; then
        show_success "Configuration Apache trouvée: $APACHE_AVAILABLE/$domain_name.conf"
        
        # Extraire le chemin du document root
        local document_root=$(grep -i "DocumentRoot" "$APACHE_AVAILABLE/$domain_name.conf" | awk '{print $2}' | head -1)
        
        if [ -z "$document_root" ]; then
            show_error "DocumentRoot non trouvé dans la configuration"
            
            if confirm_action "Voulez-vous recréer la configuration?"; then
                # Demander le chemin du site
                local new_path=$(get_user_input "Entrez le chemin du site" "$WWW_DIR/$domain_name")
                
                # Sauvegarde de la configuration existante
                backup_file "$APACHE_AVAILABLE/$domain_name.conf"
                
                # Créer une nouvelle configuration
                cat > "$APACHE_AVAILABLE/$domain_name.conf" << EOF
<VirtualHost *:$DEFAULT_HTTP_PORT>
    ServerName $domain_name
    ServerAlias www.$domain_name
    DocumentRoot $new_path
    
    <Directory $new_path>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/${domain_name}_error.log
    CustomLog \${APACHE_LOG_DIR}/${domain_name}_access.log combined
</VirtualHost>
EOF
                
                document_root=$new_path
                show_success "Configuration recréée"
            fi
        else
            show_success "DocumentRoot trouvé: $document_root"
        fi
    else
        show_error "Configuration Apache non trouvée: $APACHE_AVAILABLE/$domain_name.conf"
        
        if confirm_action "Voulez-vous créer une nouvelle configuration?"; then
            # Demander le chemin du site
            local new_path=$(get_user_input "Entrez le chemin du site" "$WWW_DIR/$domain_name")
            
            # Créer une nouvelle configuration
            cat > "$APACHE_AVAILABLE/$domain_name.conf" << EOF
<VirtualHost *:$DEFAULT_HTTP_PORT>
    ServerName $domain_name
    ServerAlias www.$domain_name
    DocumentRoot $new_path
    
    <Directory $new_path>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/${domain_name}_error.log
    CustomLog \${APACHE_LOG_DIR}/${domain_name}_access.log combined
</VirtualHost>
EOF
            
            document_root=$new_path
            show_success "Nouvelle configuration créée"
        else
            return 1
        fi
    fi
    
    # Vérifier si le site est activé
    echo -e "\n${YELLOW}Vérification de l'activation du site...${NC}"
    
    if [ -L "$APACHE_ENABLED/$domain_name.conf" ]; then
        show_success "Site activé"
    else
        show_error "Site non activé"
        
        if confirm_action "Voulez-vous activer le site?"; then
            if a2ensite "$domain_name.conf" > /dev/null 2>&1; then
                show_success "Site activé avec succès"
            else
                show_error "Échec de l'activation du site"
            fi
        fi
    fi
    
    # Vérifier le répertoire du site
    if [ -n "$document_root" ]; then
        echo -e "\n${YELLOW}Vérification du répertoire du site...${NC}"
        
        if [ -d "$document_root" ]; then
            show_success "Répertoire $document_root trouvé"
            
            # Vérifier les permissions
            local current_owner=$(stat -c "%U:%G" "$document_root")
            local current_perms=$(stat -c "%a" "$document_root")
            
            echo -e "Propriétaire actuel: $current_owner (recommandé: $DEFAULT_OWNER)"
            echo -e "Permissions actuelles: $current_perms (recommandé: $DEFAULT_PERMISSIONS)"
            
            if [ "$current_owner" != "$DEFAULT_OWNER" ] || [ "$current_perms" != "$DEFAULT_PERMISSIONS" ]; then
                if confirm_action "Voulez-vous corriger les permissions?"; then
                    log_info "Correction des permissions pour $document_root..."
                    chown -R $DEFAULT_OWNER "$document_root"
                    chmod -R $DEFAULT_PERMISSIONS "$document_root"
                    show_success "Permissions corrigées"
                fi
            fi
            
            # Vérifier la présence d'un fichier index
            if [ ! -f "$document_root/index.html" ] && [ ! -f "$document_root/index.php" ]; then
                show_warning "Aucun fichier index trouvé"
                
                if confirm_action "Voulez-vous créer un fichier index.html par défaut?"; then
                    generate_default_index "$document_root" "$domain_name" "réparé"
                fi
            else
                show_success "Fichier index trouvé"
            fi
        else
            show_error "Répertoire $document_root non trouvé"
            
            if confirm_action "Voulez-vous créer le répertoire?"; then
                if mkdir -p "$document_root"; then
                    chown -R $DEFAULT_OWNER "$document_root"
                    chmod -R $DEFAULT_PERMISSIONS "$document_root"
                    
                    # Créer un fichier index par défaut
                    generate_default_index "$document_root" "$domain_name" "réparé"
                else
                    show_error "Échec de la création du répertoire"
                fi
            fi
        fi
    fi
    
    # Vérifier la configuration Apache
    echo -e "\n${YELLOW}Vérification de la syntaxe de la configuration...${NC}"
    if apache2ctl configtest > /dev/null 2>&1; then
        show_success "Syntaxe de la configuration valide"
    else
        show_error "Erreurs de syntaxe dans la configuration"
        if confirm_action "Afficher les erreurs de syntaxe?"; then
            apache2ctl configtest
        fi
    fi
    
    # Proposer le redémarrage d'Apache
    if confirm_action "Voulez-vous redémarrer Apache pour appliquer les changements?"; then
        if ! restart_apache; then
            show_error "Échec du redémarrage d'Apache"
        fi
    fi
    
    # Vérification DNS
    if confirm_action "Voulez-vous vérifier la configuration DNS pour ce domaine?"; then
        check_dns "$domain_name"
    fi
    
    return 0
}

# Fonction pour vérifier les DNS
check_dns() {
    local domain=$1
    
    if [ -z "$domain" ]; then
        domain=$(get_user_input "Entrez le nom de domaine à vérifier" "" true)
    fi
    
    # Valider le nom de domaine
    if ! validate_domain "$domain"; then
        show_error "Nom de domaine invalide: $domain"
        return 1
    fi
    
    show_header "Vérification DNS pour $domain"
    
    local server_ip=$(get_server_ip)
    
    show_info "Configuration DNS requise:"
    echo -e "Type A:\t$domain\t→\t$server_ip"
    echo -e "Type A:\twww.$domain\t→\t$server_ip"
    
    echo -e "\n${YELLOW}Vérification des enregistrements DNS...${NC}"
    
    # Vérifier l'enregistrement principal
    echo -ne "Vérification de $domain: "
    if command_exists host; then
        if host "$domain" > /dev/null 2>&1; then
            local domain_ip=$(host "$domain" | grep "has address" | head -1 | awk '{print $4}')
            if [ "$domain_ip" = "$server_ip" ]; then
                show_success "OK - Pointe vers $domain_ip"
            else
                show_error "ERREUR - Pointe vers $domain_ip au lieu de $server_ip"
            fi
        else
            show_error "ERREUR - Enregistrement DNS non trouvé"
        fi
    else
        if ping -c 1 "$domain" > /dev/null 2>&1; then
            local domain_ip=$(ping -c 1 "$domain" | grep "PING" | head -1 | awk -F'[()]' '{print $2}')
            if [ "$domain_ip" = "$server_ip" ]; then
                show_success "OK - Pointe vers $domain_ip"
            else
                show_error "ERREUR - Pointe vers $domain_ip au lieu de $server_ip"
            fi
        else
            show_error "ERREUR - Enregistrement DNS non trouvé"
        fi
    fi
    
    # Vérifier l'enregistrement www
    echo -ne "Vérification de www.$domain: "
    if command_exists host; then
        if host "www.$domain" > /dev/null 2>&1; then
            local www_ip=$(host "www.$domain" | grep "has address" | head -1 | awk '{print $4}')
            if [ "$www_ip" = "$server_ip" ]; then
                show_success "OK - Pointe vers $www_ip"
            else
                show_error "ERREUR - Pointe vers $www_ip au lieu de $server_ip"
            fi
        else
            show_error "ERREUR - Enregistrement DNS non trouvé"
        fi
    else
        if ping -c 1 "www.$domain" > /dev/null 2>&1; then
            local www_ip=$(ping -c 1 "www.$domain" | grep "PING" | head -1 | awk -F'[()]' '{print $2}')
            if [ "$www_ip" = "$server_ip" ]; then
                show_success "OK - Pointe vers $www_ip"
            else
                show_error "ERREUR - Pointe vers $www_ip au lieu de $server_ip"
            fi
        else
            show_error "ERREUR - Enregistrement DNS non trouvé"
        fi
    fi
    
    # Afficher des conseils si des problèmes de DNS sont détectés
    if ! host "$domain" > /dev/null 2>&1 || ! host "www.$domain" > /dev/null 2>&1; then
        echo -e "\n${YELLOW}Conseils pour la configuration DNS:${NC}"
        echo "1. Connectez-vous à votre registraire de domaine ou fournisseur DNS"
        echo "2. Ajoutez ou modifiez les enregistrements suivants:"
        echo "   - Type A: $domain → $server_ip"
        echo "   - Type A: www.$domain → $server_ip"
        echo "3. La propagation des DNS peut prendre de 15 minutes à 48 heures"
        echo "4. Utilisez des services comme dnschecker.org pour vérifier la propagation"
    fi
    
    return 0
}

# Fonction pour importer un site web depuis différentes sources
import_site() {
    log_info "Importation d'un site web..."
    
    # Vérifier si Apache est installé
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé. Installation requise avant d'importer un site."
        
        if confirm_action "Voulez-vous installer Apache maintenant?"; then
            install_apache
        else
            return 1
        fi
    fi
    
    show_header "Importation d'un site web"
    
    # 1. Demander le nom du site
    local site_name=$(get_user_input "Entrez le nom du site (sera utilisé comme nom de dossier)" "" true)
    
    # 2. Demander le nom de domaine
    local domain=$(get_user_input "Entrez le nom de domaine (ex: example.com)" "" true)
    
    # Valider le nom de domaine
    if ! validate_domain "$domain"; then
        show_error "Nom de domaine invalide: $domain"
        return 1
    fi
    
    # 3. Vérifier si le domaine existe déjà
    if [ -f "$APACHE_AVAILABLE/$domain.conf" ]; then
        show_error "Une configuration pour $domain existe déjà"
        
        if ! confirm_action "Voulez-vous écraser la configuration existante?"; then
            return 1
        fi
        
        # Désactiver le site existant
        log_info "Désactivation du site existant..."
        a2dissite "$domain.conf" >/dev/null 2>&1
    fi
    
    # 4. Sélectionner la méthode d'importation
    show_menu "Sélectionnez la source d'importation" \
        "Importer depuis un répertoire local" \
        "Importer depuis une archive (zip/tar.gz)" \
        "Importer depuis un dépôt Git" \
        "back"
    
    local choice=$(get_user_choice "Entrez votre choix" 3)
    
    # 5. Préparer le répertoire de destination
    local target_dir="$WWW_DIR/$site_name"
    
    # Vérifier si le répertoire existe déjà
    if [ -d "$target_dir" ]; then
        show_warning "Le répertoire $target_dir existe déjà"
        
        if confirm_action "Voulez-vous supprimer le contenu existant?"; then
            log_info "Suppression du contenu existant..."
            rm -rf "$target_dir"
        else
            if ! confirm_action "Voulez-vous continuer et écraser les fichiers existants?"; then
                return 1
            fi
        fi
    fi
    
    # Créer le répertoire s'il n'existe pas
    if [ ! -d "$target_dir" ]; then
        log_info "Création du répertoire $target_dir..."
        mkdir -p "$target_dir"
    fi
    
    # 6. Importer selon la méthode choisie
    case $choice in
        1) # Importer depuis un répertoire local
            local source_dir=$(get_user_input "Entrez le chemin du répertoire source" "" true)
            
            if [ ! -d "$source_dir" ]; then
                show_error "Le répertoire source $source_dir n'existe pas"
                return 1
            fi
            
            log_info "Copie des fichiers depuis $source_dir vers $target_dir..."
            cp -r "$source_dir"/* "$target_dir"/ 2>/dev/null
            
            if [ $? -ne 0 ]; then
                show_warning "Certains fichiers n'ont pas pu être copiés. Vérifiez les permissions."
            fi
            ;;
            
        2) # Importer depuis une archive
            local archive_path=$(get_user_input "Entrez le chemin de l'archive (zip ou tar.gz)" "" true)
            
            if [ ! -f "$archive_path" ]; then
                show_error "L'archive $archive_path n'existe pas"
                return 1
            fi
            
            log_info "Extraction de l'archive $archive_path vers $target_dir..."
            
            # Déterminer le type d'archive
            if [[ "$archive_path" == *.zip ]]; then
                # Vérifier si unzip est installé
                if ! command_exists unzip; then
                    show_warning "La commande unzip n'est pas installée"
                    if confirm_action "Voulez-vous installer unzip maintenant?"; then
                        if apt update -qq && apt install -y unzip; then
                            show_success "unzip installé avec succès"
                        else
                            show_error "Échec de l'installation de unzip"
                            return 1
                        fi
                    else
                        show_error "unzip est nécessaire pour extraire les archives .zip"
                        return 1
                    fi
                fi
                
                unzip -q "$archive_path" -d "$target_dir"
            elif [[ "$archive_path" == *.tar.gz || "$archive_path" == *.tgz ]]; then
                tar -xzf "$archive_path" -C "$target_dir"
            else
                show_error "Format d'archive non supporté. Utilisez zip ou tar.gz"
                return 1
            fi
            
            # Vérifier si les fichiers sont dans un sous-répertoire
            local subdirs=$(find "$target_dir" -maxdepth 1 -type d | wc -l)
            if [ "$subdirs" -eq 2 ]; then
                # Il n'y a qu'un seul sous-répertoire, les fichiers sont probablement dedans
                local subdir=$(find "$target_dir" -maxdepth 1 -type d -not -path "$target_dir" | head -1)
                if [ -n "$subdir" ]; then
                    log_info "Déplacement des fichiers depuis $subdir vers $target_dir..."
                    mv "$subdir"/* "$target_dir"/ 2>/dev/null
                    rmdir "$subdir" 2>/dev/null
                fi
            fi
            ;;
            
        3) # Importer depuis un dépôt Git
            # Vérifier si git est installé
            if ! command_exists git; then
                show_warning "Git n'est pas installé"
                if confirm_action "Voulez-vous installer git maintenant?"; then
                    if apt update -qq && apt install -y git; then
                        show_success "git installé avec succès"
                    else
                        show_error "Échec de l'installation de git"
                        return 1
                    fi
                else
                    show_error "git est nécessaire pour cloner des dépôts"
                    return 1
                fi
            fi
            
            local repo_url=$(get_user_input "Entrez l'URL du dépôt Git" "" true)
            local branch=$(get_user_input "Entrez la branche à cloner (laisser vide pour la branche par défaut)" "")
            
            log_info "Clonage du dépôt $repo_url vers $target_dir..."
            
            if [ -z "$branch" ]; then
                git clone --depth=1 "$repo_url" "$target_dir"
            else
                git clone --depth=1 -b "$branch" "$repo_url" "$target_dir"
            fi
            
            if [ $? -ne 0 ]; then
                show_error "Échec du clonage du dépôt Git"
                return 1
            fi
            
            # Supprimer le dossier .git pour économiser de l'espace
            rm -rf "$target_dir/.git"
            ;;
            
        0) # Retour
            return 0
            ;;
            
        *) 
            show_error "Option invalide"
            return 1
            ;;
    esac
    
    # 7. Configurer les permissions
    log_info "Configuration des permissions..."
    chown -R $DEFAULT_OWNER "$target_dir"
    chmod -R $DEFAULT_PERMISSIONS "$target_dir"
    find "$target_dir" -type f -exec chmod $DEFAULT_FILE_PERMISSIONS {} \;
    
    # 8. Vérifier la présence d'un fichier index
    if [ ! -f "$target_dir/index.html" ] && [ ! -f "$target_dir/index.php" ]; then
        show_warning "Aucun fichier index trouvé"
        
        if confirm_action "Voulez-vous créer un fichier index.html par défaut?"; then
            generate_default_index "$target_dir" "$domain" "importé"
        fi
    fi
    
    # 9. Créer la configuration Apache
    log_info "Création de la configuration Apache..."
    
    # Sauvegarde si la configuration existe déjà
    if [ -f "$APACHE_AVAILABLE/$domain.conf" ]; then
        backup_file "$APACHE_AVAILABLE/$domain.conf"
    fi
    
    # Créer la configuration
    cat > "$APACHE_AVAILABLE/$domain.conf" <<EOL
<VirtualHost *:$DEFAULT_HTTP_PORT>
    ServerName $domain
    ServerAlias www.$domain
    DocumentRoot $target_dir
    
    <Directory $target_dir>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/$domain-error.log
    CustomLog \${APACHE_LOG_DIR}/$domain-access.log combined
    
    # Configuration optimisée
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript application/x-javascript
    </IfModule>
    
    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType image/jpg "access plus 1 year"
        ExpiresByType image/jpeg "access plus 1 year"
        ExpiresByType image/gif "access plus 1 year"
        ExpiresByType image/png "access plus 1 year"
        ExpiresByType image/webp "access plus 1 year"
        ExpiresByType text/css "access plus 1 month"
        ExpiresByType application/pdf "access plus 1 month"
        ExpiresByType text/javascript "access plus 1 month"
        ExpiresByType application/javascript "access plus 1 month"
        ExpiresByType image/x-icon "access plus 1 year"
        ExpiresDefault "access plus 2 days"
    </IfModule>
</VirtualHost>
EOL
    
    # 10. Activer le site
    log_info "Activation du site..."
    a2ensite "$domain.conf" >/dev/null 2>&1
    
    # 11. Vérifier la configuration Apache
    log_info "Vérification de la configuration Apache..."
    if ! apache2ctl configtest > /dev/null 2>&1; then
        show_error "La configuration Apache contient des erreurs"
        
        if confirm_action "Voulez-vous consulter les erreurs?"; then
            apache2ctl configtest
        fi
        
        if confirm_action "Voulez-vous restaurer la configuration précédente?"; then
            if [ -f "$APACHE_AVAILABLE/$domain.conf.bak" ]; then
                cp "$APACHE_AVAILABLE/$domain.conf.bak" "$APACHE_AVAILABLE/$domain.conf"
                show_success "Configuration restaurée"
            else
                rm "$APACHE_AVAILABLE/$domain.conf"
                show_info "Configuration supprimée"
            fi
            
            a2dissite "$domain.conf" >/dev/null 2>&1
            return 1
        fi
    fi
    
    # 12. Redémarrer Apache
    log_info "Redémarrage d'Apache..."
    if ! restart_apache; then
        show_error "Échec du redémarrage d'Apache"
        return 1
    fi
    
    # 13. Afficher les informations de déploiement
    show_success "Site $domain importé et déployé avec succès!"
    
    # 14. Afficher les informations DNS
    local detected_ip=$(get_server_ip)
    local server_ip=$(get_user_input "Entrez l'adresse IP publique du serveur" "$detected_ip" true)
    
    show_info "Pour que votre site soit accessible, configurez les DNS suivants:"
    echo -e "Type A: ${BOLD_YELLOW}$domain${NC}\t→\t${BOLD_CYAN}$server_ip${NC}"
    echo -e "Type A: ${BOLD_YELLOW}www.$domain${NC}\t→\t${BOLD_CYAN}$server_ip${NC}"
    
    # 15. Proposer la configuration HTTPS
    if confirm_action "Voulez-vous configurer HTTPS pour ce site maintenant?"; then
        configure_https "$domain"
    else
        show_info "Vous pourrez configurer HTTPS plus tard via le menu SSL/HTTPS."
    fi
    
    return 0
}

# Liste les sites disponibles avec leur configuration SSL
list_available_sites() {
    local title=${1:-"Sites disponibles"}
    
    show_header "$title"
    
    local count=0
    local total_sites=0
    
    # Compter le nombre total de sites activés
    total_sites=$(find $APACHE_ENABLED -type l | wc -l)
    
    if [ $total_sites -eq 0 ]; then
        show_warning "Aucun site activé trouvé"
        return 1
    fi
    
    # Afficher les sites activés avec leur statut SSL
    for site_config in $(find $APACHE_ENABLED -type l); do
        count=$((count + 1))
        local site_name=$(basename $site_config)
        local domain=$(grep -m 1 "ServerName" "$site_config" | awk '{print $2}')
        
        if [ -z "$domain" ]; then
            domain="<Domaine non défini>"
        fi
        
        # Vérifier si le site a SSL configuré
        if grep -q "SSLEngine on" "$site_config"; then
            echo -e "$count. ${GREEN}$domain${NC} [${GREEN}SSL activé${NC}]"
        else
            echo -e "$count. ${GREEN}$domain${NC} [${RED}SSL non activé${NC}]"
        fi
    done
    
    echo ""
    return 0
}

# Fonction pour générer un fichier index.html par défaut
generate_default_index() {
    local target_dir=$1
    local domain_name=$2
    local site_type=${3:-"nouveau"}
    
    if [ ! -d "$target_dir" ]; then
        log_error "Répertoire cible non trouvé: $target_dir"
        return 1
    fi
    
    cat > "$target_dir/index.html" <<EOL
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bienvenue sur $domain_name</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 0;
            color: #333;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            background: linear-gradient(to bottom right, #f5f7fa, #c3cfe2);
        }
        .container {
            max-width: 800px;
            padding: 30px;
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        h1 {
            color: #2c3e50;
            margin-bottom: 20px;
        }
        p {
            margin-bottom: 20px;
        }
        .footer {
            margin-top: 30px;
            font-size: 0.85em;
            color: #7f8c8d;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Bienvenue sur $domain_name</h1>
EOL

    case "$site_type" in
        "nouveau")
            echo '        <p>Ce site est hébergé par SiteWeb Manager.</p>' >> "$target_dir/index.html"
            echo '        <p>Remplacez ce fichier <code>index.html</code> par votre contenu.</p>' >> "$target_dir/index.html"
            ;;
        "importé")
            echo '        <p>Site importé avec SiteWeb Manager.</p>' >> "$target_dir/index.html"
            ;;
        "réparé")
            echo '        <p>Ce site a été réparé par SiteWeb Manager.</p>' >> "$target_dir/index.html"
            ;;
        *)
            echo '        <p>Site géré par SiteWeb Manager.</p>' >> "$target_dir/index.html"
            ;;
    esac

    cat >> "$target_dir/index.html" <<EOL
        <div class="footer">
            <p>Site créé le $(date '+%d/%m/%Y à %H:%M')</p>
        </div>
    </div>
</body>
</html>
EOL

    # Définir les bonnes permissions
    chown $DEFAULT_OWNER "$target_dir/index.html"
    chmod $DEFAULT_FILE_PERMISSIONS "$target_dir/index.html"
    
    log_info "Fichier index.html par défaut créé pour $domain_name"
    return 0
} 