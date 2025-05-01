#!/bin/bash
# Fonctions de gestion SSL/HTTPS pour SiteWebManager

# Fonction principale pour gérer le menu SSL
manage_ssl() {
    show_header "Gestion SSL/HTTPS"
    
    show_menu "Options SSL/HTTPS" \
        "Installation de Certbot (Let's Encrypt)" \
        "Ajouter un certificat SSL à un site" \
        "Renouveler les certificats" \
        "Vérifier les certificats SSL existants" \
        "Supprimer un certificat SSL" \
        "Configurer la redirection HTTP vers HTTPS" \
        "Tester la configuration SSL d'un site" \
        "back"
    
    choice=$(get_user_choice "Entrez votre choix" 7)
    
    case $choice in
        1) install_certbot ;;
        2) add_ssl_to_site ;;
        3) renew_certificates ;;
        4) check_certificates ;;
        5) remove_ssl ;;
        6) configure_https_redirect ;;
        7) test_ssl_config ;;
        0) return ;;
        *) 
            show_error "Option invalide"
            sleep 2
            manage_ssl
            ;;
    esac
}

# Installer Certbot (Let's Encrypt)
install_certbot() {
    log_info "Installation de Certbot..."
    
    # Vérifier si Certbot est déjà installé
    if command_exists certbot; then
        show_warning "Certbot est déjà installé"
        show_certbot_info
        return 0
    fi
    
    # Vérifier si Apache est installé
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé. Installation requise avant de configurer SSL."
        
        if confirm_action "Voulez-vous installer Apache maintenant?"; then
            install_apache
        else
            return 1
        fi
    fi
    
    # Installation de Certbot et du plugin Apache
    show_info "Installation de Certbot et du plugin Apache..."
    
    if apt update && apt install -y certbot python3-certbot-apache; then
        show_success "Certbot et le plugin Apache installés avec succès"
        
        # Activer le module SSL d'Apache si nécessaire
        a2enmod ssl >/dev/null 2>&1
        
        # Redémarrer Apache
        systemctl restart apache2
        
        show_certbot_info
        
        return 0
    else
        show_error "Échec de l'installation de Certbot"
        return 1
    fi
}

# Afficher les informations sur Certbot
show_certbot_info() {
    echo -e "\n${YELLOW}Informations sur Certbot :${NC}"
    certbot --version
    
    echo -e "\n${YELLOW}Certificats existants :${NC}"
    certbot certificates
}

# Ajouter un certificat SSL à un site
add_ssl_to_site() {
    log_info "Ajout d'un certificat SSL à un site..."
    
    # Vérifier si Certbot est installé
    if ! command_exists certbot; then
        show_error "Certbot n'est pas installé"
        
        if confirm_action "Voulez-vous installer Certbot maintenant?"; then
            install_certbot
        else
            return 1
        fi
    fi
    
    # Vérifier le plugin Apache
    if ! dpkg -l | grep -q python3-certbot-apache; then
        show_warning "Le plugin Apache pour Certbot n'est pas installé"
        
        if confirm_action "Voulez-vous l'installer maintenant?"; then
            apt update && apt install -y python3-certbot-apache
            systemctl restart apache2
        else
            return 1
        fi
    fi
    
    # Lister les sites disponibles
    list_available_sites "Sélectionnez un site pour ajouter SSL"
    
    # Demander le nom du site
    local choice=$(get_user_choice "Entrez le numéro du site" $(expr $(find $APACHE_ENABLED -type l | wc -l) + 1))
    
    if [ $choice -eq 0 ]; then
        return 0
    fi
    
    local site_config=$(ls -1 $APACHE_ENABLED | sed -n "${choice}p")
    
    if [ -z "$site_config" ]; then
        show_error "Sélection invalide"
        return 1
    fi
    
    # Extraire le domaine de la configuration
    local domain=$(grep -m 1 "ServerName" "$APACHE_ENABLED/$site_config" | awk '{print $2}')
    
    if [ -z "$domain" ]; then
        show_error "Impossible de déterminer le domaine pour $site_config"
        return 1
    fi
    
    # Demander des domaines supplémentaires
    local add_domains=""
    if confirm_action "Voulez-vous ajouter des domaines supplémentaires au certificat?"; then
        add_domains=$(get_user_input "Entrez les domaines supplémentaires, séparés par des espaces" "")
    fi
    
    # Construction de la commande Certbot
    local certbot_cmd="certbot --apache -d $domain"
    
    # Ajouter les domaines supplémentaires
    for add_domain in $add_domains; do
        certbot_cmd="$certbot_cmd -d $add_domain"
    done
    
    # Demander si l'utilisateur veut forcer la redirection HTTPS
    local redirect=""
    if confirm_action "Voulez-vous forcer la redirection HTTP vers HTTPS?"; then
        redirect="2" # Option pour forcer la redirection
    else
        redirect="1" # Option pour ne pas forcer la redirection
    fi
    
    # Exécuter la commande Certbot
    log_info "Obtention du certificat pour $domain..."
    echo -e "${GREEN}La commande suivante va être exécutée : $certbot_cmd${NC}"
    
    # Simulation de l'entrée utilisateur pour la redirection
    {
        sleep 2
        echo "$redirect"
    } | $certbot_cmd
    
    # Vérifier le résultat
    if [ $? -eq 0 ]; then
        show_success "Certificat SSL installé avec succès pour $domain"
        return 0
    else
        show_error "Échec de l'installation du certificat SSL pour $domain"
        return 1
    fi
}

# Renouveler les certificats
renew_certificates() {
    log_info "Renouvellement des certificats SSL..."
    
    # Vérifier si Certbot est installé
    if ! command_exists certbot; then
        show_error "Certbot n'est pas installé"
        return 1
    fi
    
    # Afficher les certificats existants
    show_info "Certificats existants :"
    certbot certificates
    
    # Test de renouvellement
    if confirm_action "Voulez-vous effectuer un test de renouvellement?"; then
        show_info "Test de renouvellement des certificats..."
        certbot renew --dry-run
    fi
    
    # Renouvellement réel
    if confirm_action "Voulez-vous renouveler les certificats maintenant?"; then
        show_info "Renouvellement des certificats..."
        if certbot renew; then
            show_success "Certificats renouvelés avec succès"
            return 0
        else
            show_error "Problème lors du renouvellement des certificats"
            return 1
        fi
    fi
    
    return 0
}

# Vérifier les certificats existants
check_certificates() {
    log_info "Vérification des certificats SSL..."
    
    # Vérifier si Certbot est installé
    if ! command_exists certbot; then
        show_error "Certbot n'est pas installé"
        return 1
    fi
    
    # Afficher les certificats existants
    show_info "Certificats existants :"
    certbot certificates
    
    # Vérifier la date d'expiration
    local expiry_date=$(certbot certificates | grep "Expiry Date" | head -1 | awk '{print $3, $4, $5, $6}')
    
    if [ -n "$expiry_date" ]; then
        echo -e "\n${YELLOW}Date d'expiration du premier certificat : $expiry_date${NC}"
        
        # Convertir la date en timestamp pour la comparaison
        local expiry_timestamp=$(date -d "$expiry_date" +%s)
        local current_timestamp=$(date +%s)
        local days_left=$(( ($expiry_timestamp - $current_timestamp) / 86400 ))
        
        echo -e "${YELLOW}Jours restants avant l'expiration : $days_left${NC}"
        
        if [ $days_left -lt 30 ]; then
            show_warning "Le certificat expire dans moins de 30 jours"
            
            if confirm_action "Voulez-vous renouveler les certificats maintenant?"; then
                renew_certificates
            fi
        else
            show_success "Les certificats sont valides pour $days_left jours"
        fi
    else
        show_warning "Aucun certificat trouvé ou erreur lors de la lecture"
    fi
    
    return 0
}

# Supprimer un certificat SSL
remove_ssl() {
    log_info "Suppression d'un certificat SSL..."
    
    # Vérifier si Certbot est installé
    if ! command_exists certbot; then
        show_error "Certbot n'est pas installé"
        return 1
    fi
    
    # Afficher les certificats existants
    show_info "Certificats existants :"
    certbot certificates
    
    # Demander le domaine
    local domain=$(get_user_input "Entrez le nom de domaine pour lequel supprimer le certificat" "" true)
    
    # Confirmation
    if ! confirm_action "Êtes-vous sûr de vouloir supprimer le certificat pour $domain?"; then
        return 0
    fi
    
    # Supprimer le certificat
    log_info "Suppression du certificat pour $domain..."
    if certbot delete --cert-name $domain; then
        show_success "Certificat pour $domain supprimé avec succès"
        
        # Mettre à jour la configuration Apache
        local site_config=$(grep -l "ServerName $domain" $APACHE_AVAILABLE/*)
        
        if [ -n "$site_config" ]; then
            log_info "Mise à jour de la configuration Apache pour $domain..."
            
            # Sauvegarder la configuration
            backup_file "$site_config"
            
            # Modifier la configuration pour supprimer les directives SSL
            sed -i '/SSLEngine/d' "$site_config"
            sed -i '/SSLCertificateFile/d' "$site_config"
            sed -i '/SSLCertificateKeyFile/d' "$site_config"
            sed -i '/SSLCertificateChainFile/d' "$site_config"
            
            # Modifier le VirtualHost pour écouter sur le port 80 uniquement
            sed -i 's/<VirtualHost \*:443>/<VirtualHost *:80>/' "$site_config"
            
            # Redémarrer Apache
            systemctl restart apache2
            
            show_success "Configuration Apache mise à jour pour $domain"
        fi
        
        return 0
    else
        show_error "Échec de la suppression du certificat pour $domain"
        return 1
    fi
}

# Configurer la redirection HTTP vers HTTPS
configure_https_redirect() {
    log_info "Configuration de la redirection HTTP vers HTTPS..."
    
    # Lister les sites disponibles avec SSL
    local ssl_sites=()
    local ssl_sites_count=0
    
    for site_config in $(find $APACHE_AVAILABLE -type f); do
        if grep -q "SSLEngine on" "$site_config"; then
            local domain=$(grep -m 1 "ServerName" "$site_config" | awk '{print $2}')
            ssl_sites_count=$((ssl_sites_count + 1))
            ssl_sites[$ssl_sites_count]="$site_config"
            echo -e "$ssl_sites_count. ${GREEN}$domain${NC}"
        fi
    done
    
    if [ $ssl_sites_count -eq 0 ]; then
        show_error "Aucun site avec SSL trouvé"
        return 1
    fi
    
    # Demander le site à configurer
    local choice=$(get_user_choice "Entrez le numéro du site" $ssl_sites_count)
    
    if [ $choice -eq 0 ]; then
        return 0
    fi
    
    local site_config="${ssl_sites[$choice]}"
    local domain=$(grep -m 1 "ServerName" "$site_config" | awk '{print $2}')
    
    # Vérifier si la redirection est déjà configurée
    if grep -q "RewriteEngine on" "$site_config" && grep -q "RewriteRule ^ https://%{SERVER_NAME}" "$site_config"; then
        show_warning "La redirection HTTPS est déjà configurée pour $domain"
        
        if confirm_action "Voulez-vous désactiver la redirection?"; then
            # Sauvegarder la configuration
            backup_file "$site_config"
            
            # Supprimer les règles de redirection
            sed -i '/RewriteEngine on/d' "$site_config"
            sed -i '/RewriteCond %{HTTPS} off/d' "$site_config"
            sed -i '/RewriteRule \^ https:\/\/%{SERVER_NAME}/d' "$site_config"
            
            # Redémarrer Apache
            systemctl restart apache2
            
            show_success "Redirection HTTPS désactivée pour $domain"
        fi
        
        return 0
    fi
    
    # Configurer la redirection
    log_info "Configuration de la redirection HTTP vers HTTPS pour $domain..."
    
    # Sauvegarder la configuration
    backup_file "$site_config"
    
    # Trouver le bloc VirtualHost pour le port 80
    if ! grep -q "<VirtualHost \*:80>" "$site_config"; then
        show_error "Configuration VirtualHost pour le port 80 non trouvée"
        return 1
    fi
    
    # Ajouter les règles de redirection
    sed -i '/<VirtualHost \*:80>/a \
    RewriteEngine on\
    RewriteCond %{HTTPS} off\
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [L,R=301]' "$site_config"
    
    # S'assurer que le module rewrite est activé
    a2enmod rewrite >/dev/null 2>&1
    
    # Redémarrer Apache
    systemctl restart apache2
    
    show_success "Redirection HTTP vers HTTPS configurée pour $domain"
    return 0
}

# Tester la configuration SSL d'un site
test_ssl_config() {
    log_info "Test de la configuration SSL..."
    
    # Vérifier si OpenSSL est installé
    if ! command_exists openssl; then
        show_warning "OpenSSL n'est pas installé. Installation..."
        apt update && apt install -y openssl
    fi
    
    # Demander le domaine à tester
    local domain=$(get_user_input "Entrez le nom de domaine à tester" "" true)
    
    # Tester le domaine avec OpenSSL
    show_info "Test du certificat SSL pour $domain..."
    echo -e "${YELLOW}Informations sur le certificat :${NC}"
    echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -noout -dates -issuer -subject
    
    # Tester avec la commande SSL Labs si disponible
    if command_exists sslscan; then
        echo -e "\n${YELLOW}Résultats du scan SSL :${NC}"
        sslscan --no-colour $domain
    else
        if confirm_action "Voulez-vous installer sslscan pour une analyse plus détaillée?"; then
            apt update && apt install -y sslscan
            echo -e "\n${YELLOW}Résultats du scan SSL :${NC}"
            sslscan --no-colour $domain
        fi
    fi
    
    # Afficher les conseils
    echo -e "\n${YELLOW}Conseils de sécurité SSL :${NC}"
    echo -e "1. Assurez-vous que votre certificat n'est pas expiré"
    echo -e "2. Utilisez TLS 1.2 ou supérieur et désactivez SSL v3 et TLS 1.0/1.1"
    echo -e "3. Configurez une liste de chiffrement forte"
    echo -e "4. Activez HTTP Strict Transport Security (HSTS)"
    echo -e "5. Supprimez les protocoles et chiffrements faibles"
    
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

# Configuration automatique du cron pour le renouvellement des certificats
configure_ssl_renewal_cron() {
    log_info "Configuration du renouvellement automatique des certificats..."
    
    # Vérifier si Certbot est installé
    if ! command_exists certbot; then
        show_error "Certbot n'est pas installé"
        return 1
    fi
    
    # Vérifier si la tâche cron existe déjà
    if crontab -l 2>/dev/null | grep -q "certbot renew"; then
        show_warning "Une tâche cron pour Certbot existe déjà"
        
        if confirm_action "Voulez-vous la remplacer?"; then
            # Supprimer l'ancienne tâche
            crontab -l 2>/dev/null | grep -v "certbot renew" | crontab -
        else
            return 0
        fi
    fi
    
    # Ajouter la tâche cron pour le renouvellement
    show_info "Ajout de la tâche cron pour le renouvellement automatique..."
    
    # Créer la tâche cron pour s'exécuter à 3h du matin deux fois par mois
    (crontab -l 2>/dev/null; echo "0 3 1,15 * * certbot renew --quiet --post-hook \"systemctl reload apache2\"") | crontab -
    
    show_success "Tâche cron configurée pour le renouvellement automatique des certificats"
    
    # Vérifier la configuration
    crontab -l | grep "certbot renew"
    
    return 0
} 