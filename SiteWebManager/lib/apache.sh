#!/bin/bash
# Fonctions de gestion d'Apache

# Installer Apache
install_apache() {
    log_info "Installation d'Apache..."
    
    # Vérification si Apache est déjà installé
    if command_exists apache2; then
        show_warning "Apache est déjà installé"
        return 0
    fi
    
    # Vérifier si apt est disponible (Debian/Ubuntu)
    if ! command -v apt >/dev/null 2>&1; then
        show_error "Cette fonction nécessite apt (Debian/Ubuntu)"
        return 1
    fi
    
    # Installation d'Apache
    show_info "Installation du serveur web Apache..."
    
    # Mettre à jour la liste des paquets
    if ! apt update; then
        show_error "Échec de la mise à jour de la liste des paquets"
        return 1
    fi
    
    # Installer Apache
    if apt install -y apache2; then
        show_success "Apache installé avec succès"
        
        # Activation des modules essentiels
        log_info "Activation des modules essentiels..."
        if ! a2enmod rewrite; then
            show_warning "Échec de l'activation du module rewrite"
        fi
        
        if ! a2enmod headers; then
            show_warning "Échec de l'activation du module headers"
        fi
        
        # Configuration du pare-feu
        if command_exists ufw; then
            log_info "Vérification du statut de UFW..."
            if ufw status | grep -q "Status: active"; then
                show_info "Configuration du pare-feu..."
                ufw allow 'Apache'
                ufw allow 'Apache Full'
                show_success "Règles de pare-feu configurées"
            else
                show_info "UFW n'est pas activé, aucune règle de pare-feu configurée"
                if confirm_action "Voulez-vous activer UFW maintenant?"; then
                    if echo "y" | ufw enable; then
                        ufw allow 'Apache'
                        ufw allow 'Apache Full'
                        show_success "UFW activé et règles de pare-feu configurées"
                    else
                        show_error "Échec de l'activation d'UFW"
                    fi
                fi
            fi
        else
            show_info "UFW n'est pas installé, aucune règle de pare-feu configurée"
        fi
        
        # Démarrage du service
        log_info "Démarrage et activation d'Apache..."
        if ! systemctl start apache2; then
            show_error "Échec du démarrage d'Apache"
            return 1
        fi
        
        if ! systemctl enable apache2; then
            show_warning "Échec de l'activation du démarrage automatique d'Apache"
        fi
        
        show_info "Apache est maintenant installé et configuré"
        
        # Affichage des informations
        status_apache
        
        return 0
    else
        show_error "Échec de l'installation d'Apache"
        return 1
    fi
}

# Démarrer Apache
start_apache() {
    log_info "Démarrage d'Apache..."
    
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé"
        return 1
    fi
    
    if systemctl start apache2; then
        show_success "Apache démarré avec succès"
        return 0
    else
        show_error "Échec du démarrage d'Apache"
        return 1
    fi
}

# Arrêter Apache
stop_apache() {
    log_info "Arrêt d'Apache..."
    
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé"
        return 1
    fi
    
    if systemctl stop apache2; then
        show_success "Apache arrêté avec succès"
        return 0
    else
        show_error "Échec de l'arrêt d'Apache"
        return 1
    fi
}

# Redémarrer Apache
restart_apache() {
    log_info "Redémarrage d'Apache..."
    
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé"
        return 1
    fi
    
    if systemctl restart apache2; then
        show_success "Apache redémarré avec succès"
        return 0
    else
        show_error "Échec du redémarrage d'Apache"
        return 1
    fi
}

# Afficher le statut d'Apache
status_apache() {
    log_info "Vérification du statut d'Apache..."
    
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé"
        return 1
    fi
    
    # Afficher le statut du service
    echo -e "${YELLOW}Statut du service Apache :${NC}"
    systemctl status apache2 --no-pager
    
    # Afficher la version
    echo -e "\n${YELLOW}Version d'Apache :${NC}"
    apache2 -v
    
    # Afficher les modules actifs
    echo -e "\n${YELLOW}Modules actifs :${NC}"
    apache2ctl -M | sort
    
    # Afficher les ports en écoute
    echo -e "\n${YELLOW}Ports en écoute :${NC}"
    netstat -tlpn | grep apache2
    
    # Afficher les sites actifs
    echo -e "\n${YELLOW}Sites actifs :${NC}"
    ls -la $APACHE_ENABLED
    
    return 0
}

# Configurer le pare-feu pour Apache
configure_apache_firewall() {
    log_info "Configuration du pare-feu pour Apache..."
    
    if ! command_exists ufw; then
        show_warning "UFW n'est pas installé. Installation..."
        apt update && apt install -y ufw
    fi
    
    show_menu "Configuration du pare-feu pour Apache" \
        "Autoriser HTTP (port 80)" \
        "Autoriser HTTPS (port 443)" \
        "Autoriser HTTP et HTTPS" \
        "Bloquer HTTP (port 80)" \
        "Bloquer HTTPS (port 443)" \
        "back"
    
    choice=$(get_user_choice "Entrez votre choix" 5)
    
    case $choice in
        1) 
            ufw allow 'Apache'
            show_success "HTTP (port 80) autorisé"
            ;;
        2) 
            ufw allow 'Apache Secure'
            show_success "HTTPS (port 443) autorisé"
            ;;
        3) 
            ufw allow 'Apache Full'
            show_success "HTTP et HTTPS autorisés"
            ;;
        4) 
            ufw deny 80/tcp
            show_success "HTTP (port 80) bloqué"
            ;;
        5) 
            ufw deny 443/tcp
            show_success "HTTPS (port 443) bloqué"
            ;;
        0) return ;;
        *) 
            show_error "Option invalide"
            sleep 2
            configure_apache_firewall
            ;;
    esac
}

# Éditer la configuration principale d'Apache
edit_apache_config() {
    log_info "Édition de la configuration principale d'Apache..."
    
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé"
        return 1
    fi
    
    # Sauvegarde du fichier de configuration
    backup_file "/etc/apache2/apache2.conf"
    
    # Éditer avec l'éditeur par défaut
    ${EDITOR:-nano} /etc/apache2/apache2.conf
    
    # Vérifier la syntaxe
    show_info "Vérification de la syntaxe..."
    if apache2ctl configtest; then
        show_success "Syntaxe correcte"
        
        # Demander le redémarrage d'Apache
        if confirm_action "Voulez-vous redémarrer Apache pour appliquer les changements?"; then
            restart_apache
        fi
    else
        show_error "Erreur de syntaxe détectée"
        if confirm_action "Voulez-vous restaurer la configuration précédente?"; then
            cp "/etc/apache2/apache2.conf.bak" "/etc/apache2/apache2.conf"
            show_success "Configuration restaurée"
        fi
    fi
}

# Vérifier la configuration d'Apache
check_apache_config() {
    log_info "Vérification de la configuration d'Apache..."
    
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé"
        return 1
    fi
    
    show_info "Vérification de la syntaxe de la configuration..."
    if apache2ctl configtest; then
        show_success "La configuration est valide"
    else
        show_error "La configuration contient des erreurs"
        return 1
    fi
    
    return 0
}

# Configurer les ports d'Apache
configure_apache_ports() {
    log_info "Configuration des ports d'Apache..."
    
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé"
        return 1
    fi
    
    # Vérifier si netstat est disponible
    if ! command_exists netstat && ! command_exists ss; then
        if confirm_action "L'outil netstat/ss n'est pas disponible. Voulez-vous installer net-tools?"; then
            apt update && apt install -y net-tools
        else
            show_warning "Sans netstat/ss, la vérification des ports déjà utilisés ne sera pas possible"
        fi
    fi
    
    # Récupérer le port HTTP actuel
    local current_http_port=$(grep -E "^Listen " /etc/apache2/ports.conf | grep -v 443 | awk '{print $2}')
    current_http_port=${current_http_port:-80}
    
    # Récupérer le port HTTPS actuel
    local current_https_port=$(grep -E "^Listen " /etc/apache2/ports.conf | grep 443 | awk '{print $2}')
    current_https_port=${current_https_port:-443}
    
    show_info "Port HTTP actuel : $current_http_port"
    show_info "Port HTTPS actuel : $current_https_port"
    
    # Demander le nouveau port HTTP
    local new_http_port=$(get_user_input "Entrez le nouveau port HTTP" "$current_http_port")
    
    # Valider le port
    if ! validate_port "$new_http_port"; then
        show_error "Port HTTP invalide : $new_http_port"
        return 1
    fi
    
    # Vérifier si le port est déjà utilisé
    if command_exists netstat; then
        if netstat -tuln | grep -q ":$new_http_port "; then
            if [ "$new_http_port" != "$current_http_port" ]; then
                show_error "Le port $new_http_port est déjà utilisé par un autre service"
                
                if ! confirm_action "Voulez-vous continuer quand même?"; then
                    return 1
                fi
            fi
        fi
    elif command_exists ss; then
        if ss -tuln | grep -q ":$new_http_port "; then
            if [ "$new_http_port" != "$current_http_port" ]; then
                show_error "Le port $new_http_port est déjà utilisé par un autre service"
                
                if ! confirm_action "Voulez-vous continuer quand même?"; then
                    return 1
                fi
            fi
        fi
    fi
    
    # Demander le nouveau port HTTPS
    local new_https_port=$(get_user_input "Entrez le nouveau port HTTPS" "$current_https_port")
    
    # Valider le port
    if ! validate_port "$new_https_port"; then
        show_error "Port HTTPS invalide : $new_https_port"
        return 1
    fi
    
    # Vérifier si le port est déjà utilisé
    if command_exists netstat; then
        if netstat -tuln | grep -q ":$new_https_port "; then
            if [ "$new_https_port" != "$current_https_port" ]; then
                show_error "Le port $new_https_port est déjà utilisé par un autre service"
                
                if ! confirm_action "Voulez-vous continuer quand même?"; then
                    return 1
                fi
            fi
        fi
    elif command_exists ss; then
        if ss -tuln | grep -q ":$new_https_port "; then
            if [ "$new_https_port" != "$current_https_port" ]; then
                show_error "Le port $new_https_port est déjà utilisé par un autre service"
                
                if ! confirm_action "Voulez-vous continuer quand même?"; then
                    return 1
                fi
            fi
        fi
    fi
    
    # Vérifier que les ports sont différents
    if [ "$new_http_port" = "$new_https_port" ]; then
        show_error "Les ports HTTP et HTTPS doivent être différents"
        return 1
    fi
    
    # Sauvegarde du fichier de configuration
    backup_file "/etc/apache2/ports.conf"
    
    # Modifier les ports
    log_info "Modification des ports dans la configuration Apache..."
    sed -i "s/^Listen $current_http_port$/Listen $new_http_port/" /etc/apache2/ports.conf
    sed -i "s/^Listen $current_https_port$/Listen $new_https_port/" /etc/apache2/ports.conf
    
    # Mettre à jour les hôtes virtuels
    log_info "Mise à jour des configurations de sites..."
    for site_conf in "$APACHE_AVAILABLE"/*.conf; do
        backup_file "$site_conf"
        
        # Mettre à jour les directives VirtualHost pour HTTP
        sed -i "s/<VirtualHost \*:$current_http_port>/<VirtualHost \*:$new_http_port>/" "$site_conf"
        
        # Mettre à jour les directives VirtualHost pour HTTPS
        sed -i "s/<VirtualHost \*:$current_https_port>/<VirtualHost \*:$new_https_port>/" "$site_conf"
    done
    
    # Vérifier la configuration
    log_info "Vérification de la nouvelle configuration..."
    if apache2ctl configtest; then
        show_success "Configuration des ports mise à jour avec succès"
        
        # Configurer le pare-feu pour les nouveaux ports
        if command_exists ufw && ufw status | grep -q "Status: active"; then
            show_info "Mise à jour des règles du pare-feu..."
            
            # Supprimer les anciennes règles
            log_info "Suppression des anciennes règles du pare-feu..."
            ufw delete allow $current_http_port/tcp 2>/dev/null
            ufw delete allow $current_https_port/tcp 2>/dev/null
            
            # Ajouter les nouvelles règles
            log_info "Ajout des nouvelles règles du pare-feu..."
            ufw allow $new_http_port/tcp
            ufw allow $new_https_port/tcp
            
            show_success "Règles du pare-feu mises à jour"
        fi
        
        # Redémarrer Apache
        log_info "Redémarrage d'Apache..."
        if restart_apache; then
            show_success "Apache redémarré avec succès"
        else
            show_error "Échec du redémarrage d'Apache"
            log_info "Tentative de restauration..."
            cp "/etc/apache2/ports.conf.bak" "/etc/apache2/ports.conf"
            restart_apache
            return 1
        fi
        
        # Mettre à jour la configuration
        log_info "Mise à jour des variables de configuration..."
        DEFAULT_HTTP_PORT=$new_http_port
        DEFAULT_HTTPS_PORT=$new_https_port
        
        show_warning "IMPORTANT : Notez les nouveaux ports HTTP/HTTPS : $new_http_port/$new_https_port"
        
        return 0
    else
        show_error "Erreur dans la configuration des ports"
        
        # Restaurer la configuration
        log_info "Restauration de la configuration..."
        cp "/etc/apache2/ports.conf.bak" "/etc/apache2/ports.conf"
        
        # Restaurer les fichiers de configuration des sites
        for site_conf in "$APACHE_AVAILABLE"/*.conf.bak; do
            original_conf="${site_conf%.bak}"
            if [ -f "$site_conf" ]; then
                cp "$site_conf" "$original_conf"
            fi
        done
        
        show_info "Configuration restaurée"
        return 1
    fi
}

# Optimiser les performances d'Apache
optimize_apache() {
    log_info "Optimisation des performances d'Apache..."
    
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé"
        return 1
    fi
    
    # Sauvegarde du fichier de configuration
    backup_file "/etc/apache2/apache2.conf"
    
    # Récupérer les informations système
    local cpu_cores=$(grep -c ^processor /proc/cpuinfo)
    local mem_total=$(free -m | grep Mem: | awk '{print $2}')
    
    # Calculer les valeurs optimales
    local max_clients=$((cpu_cores * 150))
    local server_limit=$((cpu_cores * 16))
    local threads_per_child=25
    
    # Si la mémoire est limitée, ajuster les valeurs
    if [ "$mem_total" -lt 2048 ]; then
        max_clients=$((cpu_cores * 50))
        server_limit=$((cpu_cores * 8))
        threads_per_child=10
    fi
    
    # Modifier le MPM prefork
    if [ -f "/etc/apache2/mods-available/mpm_prefork.conf" ]; then
        backup_file "/etc/apache2/mods-available/mpm_prefork.conf"
        
        cat > "/etc/apache2/mods-available/mpm_prefork.conf" << EOF
<IfModule mpm_prefork_module>
    StartServers             $(( cpu_cores + 2 ))
    MinSpareServers          $(( cpu_cores + 1 ))
    MaxSpareServers          $(( cpu_cores * 2 ))
    MaxRequestWorkers        $max_clients
    MaxConnectionsPerChild   1000
</IfModule>
EOF
    fi
    
    # Modifier le MPM worker
    if [ -f "/etc/apache2/mods-available/mpm_worker.conf" ]; then
        backup_file "/etc/apache2/mods-available/mpm_worker.conf"
        
        cat > "/etc/apache2/mods-available/mpm_worker.conf" << EOF
<IfModule mpm_worker_module>
    StartServers             $(( cpu_cores ))
    MinSpareThreads          $(( cpu_cores * 2 ))
    MaxSpareThreads          $(( cpu_cores * 4 ))
    ThreadLimit              64
    ThreadsPerChild          $threads_per_child
    MaxRequestWorkers        $max_clients
    MaxConnectionsPerChild   1000
</IfModule>
EOF
    fi
    
    # Modifier le MPM event
    if [ -f "/etc/apache2/mods-available/mpm_event.conf" ]; then
        backup_file "/etc/apache2/mods-available/mpm_event.conf"
        
        cat > "/etc/apache2/mods-available/mpm_event.conf" << EOF
<IfModule mpm_event_module>
    StartServers             $(( cpu_cores ))
    MinSpareThreads          $(( cpu_cores * 2 ))
    MaxSpareThreads          $(( cpu_cores * 4 ))
    ThreadLimit              64
    ThreadsPerChild          $threads_per_child
    MaxRequestWorkers        $max_clients
    MaxConnectionsPerChild   1000
</IfModule>
EOF
    fi
    
    # Activer le MPM approprié
    local best_mpm="event"
    
    # Sur les systèmes à mémoire limitée, utiliser prefork
    if [ "$mem_total" -lt 1024 ]; then
        best_mpm="prefork"
    fi
    
    a2dismod mpm_*
    a2enmod mpm_$best_mpm
    
    # Optimiser les timeouts
    sed -i "s/^Timeout .*/Timeout $APACHE_TIMEOUT/" /etc/apache2/apache2.conf
    sed -i "s/^KeepAlive .*/KeepAlive $APACHE_KEEPALIVE/" /etc/apache2/apache2.conf
    sed -i "s/^MaxKeepAliveRequests .*/MaxKeepAliveRequests $APACHE_MAX_KEEPALIVE_REQUESTS/" /etc/apache2/apache2.conf
    sed -i "s/^KeepAliveTimeout .*/KeepAliveTimeout $APACHE_KEEPALIVE_TIMEOUT/" /etc/apache2/apache2.conf
    
    # Activer la compression
    if [ ! -f "/etc/apache2/mods-enabled/deflate.load" ]; then
        a2enmod deflate
    fi
    
    # Vérifier la configuration
    if apache2ctl configtest; then
        show_success "Optimisation d'Apache effectuée avec succès"
        
        # Redémarrer Apache
        restart_apache
        
        return 0
    else
        show_error "Erreur dans la configuration d'optimisation"
        
        # Restaurer la configuration
        cp "/etc/apache2/apache2.conf.bak" "/etc/apache2/apache2.conf"
        
        for conf in "/etc/apache2/mods-available/mpm_prefork.conf" "/etc/apache2/mods-available/mpm_worker.conf" "/etc/apache2/mods-available/mpm_event.conf"; do
            if [ -f "${conf}.bak" ]; then
                cp "${conf}.bak" "$conf"
            fi
        done
        
        show_info "Configuration restaurée"
        return 1
    fi
}

# Sécuriser Apache
secure_apache() {
    log_info "Sécurisation d'Apache..."
    
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé"
        return 1
    fi
    
    # Sauvegarde des fichiers de configuration
    backup_file "/etc/apache2/conf-available/security.conf"
    
    # Activer les modules de sécurité
    a2enmod headers
    
    # Configurer les en-têtes de sécurité
    if grep -q "X-Frame-Options" "/etc/apache2/conf-available/security.conf"; then
        sed -i 's/^#\?Header set X-Frame-Options.*/Header set X-Frame-Options "SAMEORIGIN"/' "/etc/apache2/conf-available/security.conf"
    else
        echo 'Header set X-Frame-Options "SAMEORIGIN"' >> "/etc/apache2/conf-available/security.conf"
    fi
    
    if grep -q "X-Content-Type-Options" "/etc/apache2/conf-available/security.conf"; then
        sed -i 's/^#\?Header set X-Content-Type-Options.*/Header set X-Content-Type-Options "nosniff"/' "/etc/apache2/conf-available/security.conf"
    else
        echo 'Header set X-Content-Type-Options "nosniff"' >> "/etc/apache2/conf-available/security.conf"
    fi
    
    if grep -q "X-XSS-Protection" "/etc/apache2/conf-available/security.conf"; then
        sed -i 's/^#\?Header set X-XSS-Protection.*/Header set X-XSS-Protection "1; mode=block"/' "/etc/apache2/conf-available/security.conf"
    else
        echo 'Header set X-XSS-Protection "1; mode=block"' >> "/etc/apache2/conf-available/security.conf"
    fi
    
    # Masquer la signature du serveur
    sed -i 's/^ServerTokens.*/ServerTokens Prod/' "/etc/apache2/conf-available/security.conf"
    sed -i 's/^ServerSignature.*/ServerSignature Off/' "/etc/apache2/conf-available/security.conf"
    
    # Désactiver l'énumération des répertoires
    if ! grep -q "Options -Indexes" "/etc/apache2/apache2.conf"; then
        sed -i 's/Options Indexes FollowSymLinks/Options -Indexes +FollowSymLinks/' "/etc/apache2/apache2.conf"
    fi
    
    # Activer la configuration de sécurité
    a2enconf security
    
    # Vérifier la configuration
    if apache2ctl configtest; then
        show_success "Sécurisation d'Apache effectuée avec succès"
        
        # Redémarrer Apache
        restart_apache
        
        return 0
    else
        show_error "Erreur dans la configuration de sécurité"
        
        # Restaurer la configuration
        cp "/etc/apache2/conf-available/security.conf.bak" "/etc/apache2/conf-available/security.conf"
        
        show_info "Configuration restaurée"
        return 1
    fi
}

# Lister les modules Apache
list_apache_modules() {
    log_info "Liste des modules Apache..."
    
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé"
        return 1
    fi
    
    # Afficher les modules disponibles
    show_info "Modules disponibles :"
    ls -la /etc/apache2/mods-available/ | grep ".load" | awk '{print $9}' | sed 's/\.load$//'
    
    # Afficher les modules activés
    show_info "\nModules activés :"
    ls -la /etc/apache2/mods-enabled/ | grep ".load" | awk '{print $9}' | sed 's/\.load$//'
    
    return 0
}

# Activer un module Apache
enable_apache_module() {
    log_info "Activation d'un module Apache..."
    
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé"
        return 1
    fi
    
    # Lister les modules disponibles mais non activés
    local available_modules=$(ls -la /etc/apache2/mods-available/ | grep ".load" | awk '{print $9}' | sed 's/\.load$//')
    local enabled_modules=$(ls -la /etc/apache2/mods-enabled/ | grep ".load" | awk '{print $9}' | sed 's/\.load$//')
    local modules_to_enable=""
    
    for module in $available_modules; do
        if ! echo "$enabled_modules" | grep -q "$module"; then
            modules_to_enable="$modules_to_enable $module"
        fi
    done
    
    if [ -z "$modules_to_enable" ]; then
        show_info "Tous les modules disponibles sont déjà activés"
        return 0
    fi
    
    # Afficher les modules disponibles
    show_info "Modules disponibles à activer :"
    echo "$modules_to_enable" | tr ' ' '\n'
    
    # Demander le module à activer
    local module=$(get_user_input "Entrez le nom du module à activer" "" true)
    
    # Vérifier que le module existe
    if [ ! -f "/etc/apache2/mods-available/$module.load" ]; then
        show_error "Le module $module n'existe pas"
        return 1
    fi
    
    # Activer le module
    if a2enmod $module; then
        show_success "Module $module activé avec succès"
        
        # Redémarrer Apache
        if confirm_action "Voulez-vous redémarrer Apache pour appliquer les changements?"; then
            restart_apache
        fi
        
        return 0
    else
        show_error "Échec de l'activation du module $module"
        return 1
    fi
}

# Désactiver un module Apache
disable_apache_module() {
    log_info "Désactivation d'un module Apache..."
    
    if ! command_exists apache2; then
        show_error "Apache n'est pas installé"
        return 1
    fi
    
    # Lister les modules activés
    local enabled_modules=$(ls -la /etc/apache2/mods-enabled/ | grep ".load" | awk '{print $9}' | sed 's/\.load$//')
    
    if [ -z "$enabled_modules" ]; then
        show_info "Aucun module n'est activé"
        return 0
    fi
    
    # Afficher les modules activés
    show_info "Modules actuellement activés :"
    echo "$enabled_modules" | tr ' ' '\n'
    
    # Demander le module à désactiver
    local module=$(get_user_input "Entrez le nom du module à désactiver" "" true)
    
    # Vérifier que le module est activé
    if [ ! -f "/etc/apache2/mods-enabled/$module.load" ]; then
        show_error "Le module $module n'est pas activé"
        return 1
    fi
    
    # Désactiver le module
    if a2dismod $module; then
        show_success "Module $module désactivé avec succès"
        
        # Redémarrer Apache
        if confirm_action "Voulez-vous redémarrer Apache pour appliquer les changements?"; then
            restart_apache
        fi
        
        return 0
    else
        show_error "Échec de la désactivation du module $module"
        return 1
    fi
} 