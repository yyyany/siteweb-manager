#!/bin/bash
# Fonctions de gestion système

# Fonction pour mettre à jour la liste des paquets
update_package_list() {
    log_info "Mise à jour de la liste des paquets..."
    
    if apt update; then
        show_success "Liste des paquets mise à jour avec succès"
        return 0
    else
        show_error "Échec de la mise à jour de la liste des paquets"
        return 1
    fi
}

# Fonction pour mettre à jour les paquets installés
upgrade_packages() {
    log_info "Installation des mises à jour..."
    
    if apt upgrade -y; then
        show_success "Paquets mis à jour avec succès"
        return 0
    else
        show_error "Échec de la mise à jour des paquets"
        return 1
    fi
}

# Fonction complète pour mettre à jour le système
update_system() {
    log_info "Début de la mise à jour du système..."
    
    show_header "Mise à jour du système"
    
    # Mise à jour de la liste des paquets
    echo -e "${YELLOW}1. Mise à jour de la liste des paquets...${NC}"
    if update_package_list; then
        echo -e "${GREEN}✓ Liste des paquets mise à jour avec succès${NC}"
    else
        echo -e "${RED}✗ Échec de la mise à jour de la liste des paquets${NC}"
        return 1
    fi

    # Mise à niveau des paquets
    echo -e "\n${YELLOW}2. Installation des mises à jour...${NC}"
    if upgrade_packages; then
        echo -e "${GREEN}✓ Système mis à jour avec succès${NC}"
    else
        echo -e "${RED}✗ Échec de la mise à jour du système${NC}"
        return 1
    fi

    # Nettoyage
    echo -e "\n${YELLOW}3. Nettoyage des paquets obsolètes...${NC}"
    if apt autoremove -y && apt clean; then
        echo -e "${GREEN}✓ Nettoyage terminé avec succès${NC}"
    else
        echo -e "${RED}✗ Échec du nettoyage${NC}"
        return 1
    fi

    echo -e "\n${GREEN}✓ Mise à jour du système terminée${NC}"
    return 0
}

# Fonction pour gérer les paquets installés
manage_packages() {
    show_header "Gestion des paquets installés"
    
    while true; do
        echo -e "1. Installer un nouveau paquet"
        echo -e "2. Supprimer un paquet"
        echo -e "3. Rechercher un paquet"
        echo -e "4. Lister les paquets installés"
        echo -e "0. Retour"
        echo ""
        
        local choice=$(get_user_choice "Entrez votre choix" 4)
        
        case $choice in
            1) 
                local package=$(get_user_input "Entrez le nom du paquet à installer" "" true)
                log_info "Installation du paquet $package..."
                if apt install -y $package; then
                    show_success "Paquet $package installé avec succès"
                else
                    show_error "Échec de l'installation du paquet $package"
                fi
                pause
                ;;
            2) 
                local package=$(get_user_input "Entrez le nom du paquet à supprimer" "" true)
                log_info "Suppression du paquet $package..."
                if apt remove -y $package; then
                    show_success "Paquet $package supprimé avec succès"
                else
                    show_error "Échec de la suppression du paquet $package"
                fi
                pause
                ;;
            3) 
                local search_term=$(get_user_input "Entrez le terme de recherche" "" true)
                log_info "Recherche de paquets correspondant à '$search_term'..."
                apt search $search_term
                pause
                ;;
            4) 
                log_info "Liste des paquets installés..."
                dpkg --get-selections | grep -v deinstall
                pause
                ;;
            0) return ;;
            *) 
                show_error "Option invalide"
                sleep 2
                ;;
        esac
    done
}

# Fonction pour configurer le pare-feu
configure_firewall() {
    show_header "Configuration du pare-feu"
    
    # Vérifier si ufw est installé
    if ! command_exists ufw; then
        show_info "Installation de ufw..."
        apt update
        apt install -y ufw
    fi
    
    # Vérifier le statut actuel
    local ufw_status=$(ufw status | grep "Status" | awk '{print $2}')
    
    echo -e "${YELLOW}Statut actuel du pare-feu : ${NC}$ufw_status"
    echo ""
    
    while true; do
        echo -e "1. Activer le pare-feu"
        echo -e "2. Désactiver le pare-feu"
        echo -e "3. Afficher le statut"
        echo -e "4. Autoriser un port"
        echo -e "5. Bloquer un port"
        echo -e "6. Autoriser ports SSH, HTTP et HTTPS (recommandé)"
        echo -e "0. Retour"
        echo ""
        
        local choice=$(get_user_choice "Entrez votre choix" 6)
        
        case $choice in
            1) 
                log_info "Activation du pare-feu..."
                echo "y" | ufw enable
                show_success "Pare-feu activé"
                ;;
            2) 
                log_info "Désactivation du pare-feu..."
                ufw disable
                show_success "Pare-feu désactivé"
                ;;
            3) 
                log_info "Affichage du statut du pare-feu..."
                ufw status verbose
                ;;
            4) 
                local port=$(get_user_input "Entrez le numéro de port à autoriser" "" true)
                if validate_port $port; then
                    local protocol=$(get_user_input "Entrez le protocole (tcp/udp)" "tcp")
                    log_info "Autorisation du port $port/$protocol..."
                    ufw allow $port/$protocol
                    show_success "Port $port/$protocol autorisé"
                else
                    show_error "Numéro de port invalide"
                fi
                ;;
            5) 
                local port=$(get_user_input "Entrez le numéro de port à bloquer" "" true)
                if validate_port $port; then
                    local protocol=$(get_user_input "Entrez le protocole (tcp/udp)" "tcp")
                    log_info "Blocage du port $port/$protocol..."
                    ufw deny $port/$protocol
                    show_success "Port $port/$protocol bloqué"
                else
                    show_error "Numéro de port invalide"
                fi
                ;;
            6) 
                log_info "Configuration des ports essentiels..."
                ufw allow ssh
                ufw allow http
                ufw allow https
                show_success "Ports SSH (22), HTTP (80) et HTTPS (443) autorisés"
                ;;
            0) return ;;
            *) 
                show_error "Option invalide"
                sleep 2
                ;;
        esac
        
        pause
    done
}

# Fonction pour configurer SSH
configure_ssh_menu() {
    show_header "Configuration SSH"
    
    while true; do
        echo -e "1. Modifier le port SSH"
        echo -e "2. Configurer les clés SSH"
        echo -e "3. Désactiver l'authentification par mot de passe"
        echo -e "4. Vérifier la configuration"
        echo -e "0. Retour"
        echo ""
        
        local choice=$(get_user_choice "Entrez votre choix" 4)
        
        case $choice in
            1) change_ssh_port ;;
            2) configure_ssh_keys ;;
            3) disable_password_auth ;;
            4) check_ssh_config ;;
            0) return ;;
            *) 
                show_error "Option invalide"
                sleep 2
                ;;
        esac
    done
}

# Fonction pour modifier le port SSH
change_ssh_port() {
    show_header "Modification du port SSH"
    
    # Récupération du port actuel
    local current_port=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
    current_port=${current_port:-22}  # Si aucun port n'est explicitement défini, c'est 22
    
    echo -e "${YELLOW}Port SSH actuel : ${NC}$current_port"
    echo ""
    
    # Demande du nouveau port
    local new_port=$(get_user_input "Entrez le nouveau port SSH" "$current_port")
    
    # Validation du nouveau port
    if ! validate_port "$new_port"; then
        show_error "Port invalide. Veuillez entrer un nombre entre 1 et 65535"
        return 1
    fi
    
    # Vérification que l'utilisateur est conscient des implications
    show_warning "Attention! Changer le port SSH peut vous déconnecter."
    show_warning "Assurez-vous que le nouveau port est autorisé dans le pare-feu."
    if ! confirm_action "Êtes-vous sûr de vouloir changer le port SSH ?"; then
        show_info "Opération annulée"
        return 0
    fi
    
    # Sauvegarde du fichier de configuration
    log_info "Sauvegarde du fichier de configuration SSH..."
    backup_file "/etc/ssh/sshd_config"
    
    # Modification du port
    log_info "Modification du port SSH de $current_port à $new_port..."
    if grep -q "^Port " /etc/ssh/sshd_config; then
        # Le paramètre de port existe, on le remplace
        sed -i "s/^Port .*$/Port $new_port/" /etc/ssh/sshd_config
    else
        # Le paramètre de port n'existe pas, on l'ajoute
        sed -i "1i Port $new_port" /etc/ssh/sshd_config
    fi
    
    # Redémarrage du service SSH
    log_info "Redémarrage du service SSH..."
    if systemctl restart sshd; then
        show_success "Port SSH modifié avec succès"
        show_warning "IMPORTANT : Notez le nouveau port SSH : $new_port"
        show_warning "Utilisez ce port pour votre prochaine connexion SSH"
        
        # Mise à jour du pare-feu si nécessaire
        if command_exists ufw && ufw status | grep -q "Status: active"; then
            log_info "Mise à jour des règles du pare-feu..."
            ufw allow $new_port/tcp
            ufw delete allow $current_port/tcp
            show_success "Règles du pare-feu mises à jour"
        fi
        
        # Mise à jour de la configuration
        DEFAULT_SSH_PORT=$new_port
    else
        show_error "Échec du redémarrage SSH"
        show_info "Restauration de la configuration précédente..."
        cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
        systemctl restart sshd
    fi
}

# Fonction pour configurer les clés SSH
configure_ssh_keys() {
    show_header "Configuration des clés SSH"
    
    # Vérifier si le répertoire .ssh existe
    if [ ! -d "/root/.ssh" ]; then
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
    fi
    
    # Menu de configuration des clés
    while true; do
        echo -e "1. Générer une nouvelle paire de clés"
        echo -e "2. Ajouter une clé publique"
        echo -e "3. Lister les clés autorisées"
        echo -e "4. Supprimer une clé"
        echo -e "0. Retour"
        echo ""
        
        local choice=$(get_user_choice "Entrez votre choix" 4)
        
        case $choice in
            1) 
                log_info "Génération d'une nouvelle paire de clés..."
                local key_name=$(get_user_input "Nom de la clé" "id_rsa")
                ssh-keygen -t rsa -b 4096 -f "/root/.ssh/$key_name" -N ""
                show_success "Paire de clés générée dans /root/.ssh/$key_name"
                ;;
            2) 
                log_info "Ajout d'une clé publique..."
                local pub_key=$(get_user_input "Entrez la clé publique" "" true)
                echo "$pub_key" >> /root/.ssh/authorized_keys
                chmod 600 /root/.ssh/authorized_keys
                show_success "Clé publique ajoutée"
                ;;
            3) 
                log_info "Liste des clés autorisées..."
                if [ -f "/root/.ssh/authorized_keys" ]; then
                    cat /root/.ssh/authorized_keys
                else
                    show_info "Aucune clé autorisée trouvée"
                fi
                ;;
            4) 
                log_info "Suppression d'une clé..."
                if [ -f "/root/.ssh/authorized_keys" ]; then
                    local keys=$(cat /root/.ssh/authorized_keys | wc -l)
                    if [ $keys -eq 0 ]; then
                        show_info "Aucune clé à supprimer"
                    else
                        local line=$(get_user_input "Entrez le numéro de ligne de la clé à supprimer" "" true)
                        if [[ "$line" =~ ^[0-9]+$ ]] && [ $line -le $keys ]; then
                            sed -i "${line}d" /root/.ssh/authorized_keys
                            show_success "Clé supprimée"
                        else
                            show_error "Numéro de ligne invalide"
                        fi
                    fi
                else
                    show_info "Aucune clé autorisée trouvée"
                fi
                ;;
            0) return ;;
            *) 
                show_error "Option invalide"
                sleep 2
                ;;
        esac
        
        pause
    done
}

# Fonction pour désactiver l'authentification par mot de passe
disable_password_auth() {
    show_header "Désactivation de l'authentification par mot de passe SSH"
    
    # Vérifier si des clés SSH sont configurées
    if [ ! -f "/root/.ssh/authorized_keys" ] || [ $(cat /root/.ssh/authorized_keys | wc -l) -eq 0 ]; then
        show_error "Aucune clé SSH n'est configurée. Configurez d'abord des clés SSH."
        show_warning "Désactiver l'authentification par mot de passe sans clé SSH vous bloquera l'accès au serveur."
        return 1
    fi
    
    # Avertissement
    show_warning "Cette action désactivera l'authentification par mot de passe pour SSH."
    show_warning "Vous devrez utiliser des clés SSH pour vous connecter."
    
    if ! confirm_action "Êtes-vous sûr de vouloir désactiver l'authentification par mot de passe ?"; then
        show_info "Opération annulée"
        return 0
    fi
    
    # Sauvegarde du fichier de configuration
    log_info "Sauvegarde du fichier de configuration SSH..."
    backup_file "/etc/ssh/sshd_config"
    
    # Modification de la configuration
    log_info "Désactivation de l'authentification par mot de passe..."
    if grep -q "^PasswordAuthentication " /etc/ssh/sshd_config; then
        # Le paramètre existe, on le remplace
        sed -i "s/^PasswordAuthentication .*$/PasswordAuthentication no/" /etc/ssh/sshd_config
    else
        # Le paramètre n'existe pas, on l'ajoute
        echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
    fi
    
    # Redémarrage du service SSH
    log_info "Redémarrage du service SSH..."
    if systemctl restart sshd; then
        show_success "Authentification par mot de passe désactivée avec succès"
    else
        show_error "Échec du redémarrage SSH"
        show_info "Restauration de la configuration précédente..."
        cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
        systemctl restart sshd
    fi
}

# Fonction pour vérifier la configuration SSH
check_ssh_config() {
    show_header "Vérification de la configuration SSH"
    
    # Afficher les paramètres importants
    echo -e "${YELLOW}Port SSH :${NC} $(grep "^Port " /etc/ssh/sshd_config | awk '{print $2}')"
    echo -e "${YELLOW}Authentification par mot de passe :${NC} $(grep "^PasswordAuthentication " /etc/ssh/sshd_config | awk '{print $2}')"
    echo -e "${YELLOW}Authentification par clé publique :${NC} $(grep "^PubkeyAuthentication " /etc/ssh/sshd_config | awk '{print $2}')"
    echo -e "${YELLOW}Autorisation de connexion root :${NC} $(grep "^PermitRootLogin " /etc/ssh/sshd_config | awk '{print $2}')"
    
    # Vérifier la sécurité de la configuration
    echo -e "\n${YELLOW}Analyse de sécurité :${NC}"
    
    # Vérifier le port SSH
    local port=$(grep "^Port " /etc/ssh/sshd_config | awk '{print $2}')
    if [ "$port" == "22" ]; then
        echo -e "${RED}✗ Port SSH par défaut (22) utilisé. Considérez utiliser un port non standard.${NC}"
    else
        echo -e "${GREEN}✓ Port SSH non standard utilisé.${NC}"
    fi
    
    # Vérifier l'authentification par mot de passe
    if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
        echo -e "${RED}✗ Authentification par mot de passe activée.${NC}"
    else
        echo -e "${GREEN}✓ Authentification par mot de passe désactivée.${NC}"
    fi
    
    # Vérifier l'autorisation de connexion root
    if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
        echo -e "${RED}✗ Connexion root autorisée.${NC}"
    else
        echo -e "${GREEN}✓ Connexion root restreinte.${NC}"
    fi
    
    pause
}

# Fonction pour analyser les journaux
analyze_logs() {
    show_header "Analyse des journaux"
    
    while true; do
        echo -e "1. Journaux Apache (erreurs)"
        echo -e "2. Journaux Apache (accès)"
        echo -e "3. Journaux système (syslog)"
        echo -e "4. Journaux d'authentification"
        echo -e "5. Rechercher dans les journaux"
        echo -e "0. Retour"
        echo ""
        
        local choice=$(get_user_choice "Entrez votre choix" 5)
        
        case $choice in
            1) 
                log_info "Affichage des journaux d'erreur Apache..."
                tail -n 100 /var/log/apache2/error.log
                ;;
            2) 
                log_info "Affichage des journaux d'accès Apache..."
                tail -n 100 /var/log/apache2/access.log
                ;;
            3) 
                log_info "Affichage des journaux système..."
                tail -n 100 /var/log/syslog
                ;;
            4) 
                log_info "Affichage des journaux d'authentification..."
                tail -n 100 /var/log/auth.log
                ;;
            5) 
                log_info "Recherche dans les journaux..."
                local search_term=$(get_user_input "Entrez le terme à rechercher" "" true)
                local log_file=$(get_user_input "Entrez le chemin du fichier journal" "/var/log/syslog")
                grep "$search_term" "$log_file"
                ;;
            0) return ;;
            *) 
                show_error "Option invalide"
                sleep 2
                ;;
        esac
        
        pause
    done
}

# Fonction pour mettre à jour les règles de sécurité
update_security() {
    show_header "Mise à jour des règles de sécurité"
    
    # Mise à jour des paquets de sécurité
    log_info "Mise à jour des paquets de sécurité..."
    apt update
    apt upgrade -y --only-upgrade
    
    # Mettre à jour les règles du pare-feu
    if command_exists ufw && ufw status | grep -q "Status: active"; then
        log_info "Mise à jour des règles du pare-feu..."
        ufw reload
    fi
    
    # Vérifier et corriger les permissions sensibles
    log_info "Vérification des permissions des fichiers sensibles..."
    chmod 700 /root
    chmod -R 600 /etc/ssh/ssh_host_*_key
    chmod 644 /etc/ssh/ssh_host_*_key.pub
    
    # Nettoyage des fichiers temporaires
    log_info "Nettoyage des fichiers temporaires..."
    find /tmp -type f -atime +10 -delete
    
    # Vérifier les logiciels obsolètes ou non supportés
    log_info "Recherche de logiciels obsolètes..."
    apt list --upgradable
    
    show_success "Mise à jour des règles de sécurité terminée"
}

# Fonction pour configurer les sauvegardes
configure_backups() {
    show_header "Configuration des sauvegardes"
    
    while true; do
        echo -e "1. Configurer une sauvegarde des sites web"
        echo -e "2. Configurer une sauvegarde des bases de données"
        echo -e "3. Configurer une sauvegarde des configurations"
        echo -e "4. Planifier des sauvegardes automatiques"
        echo -e "5. Restaurer une sauvegarde"
        echo -e "0. Retour"
        echo ""
        
        local choice=$(get_user_choice "Entrez votre choix" 5)
        
        case $choice in
            1) backup_websites ;;
            2) backup_databases ;;
            3) backup_configs ;;
            4) schedule_backups ;;
            5) restore_backup ;;
            0) return ;;
            *) 
                show_error "Option invalide"
                sleep 2
                ;;
        esac
    done
}

# Fonction pour sauvegarder les sites web
backup_websites() {
    show_header "Sauvegarde des sites web"
    
    # Création du répertoire de sauvegarde s'il n'existe pas
    if [ ! -d "$BACKUP_DIR/websites" ]; then
        mkdir -p "$BACKUP_DIR/websites"
    fi
    
    # Date pour le nom du fichier de sauvegarde
    local date_suffix=$(date +'%Y%m%d_%H%M%S')
    
    # Demander le site à sauvegarder ou tous
    echo -e "1. Sauvegarder tous les sites"
    echo -e "2. Sauvegarder un site spécifique"
    echo -e "0. Retour"
    echo ""
    
    local choice=$(get_user_choice "Entrez votre choix" 2)
    
    case $choice in
        1) 
            log_info "Sauvegarde de tous les sites web..."
            local backup_file="$BACKUP_DIR/websites/all_websites_$date_suffix.tar.gz"
            
            if tar -czf "$backup_file" "$WWW_DIR"; then
                show_success "Sauvegarde de tous les sites créée : $backup_file"
            else
                show_error "Échec de la sauvegarde de tous les sites"
            fi
            ;;
        2) 
            # Lister les sites disponibles
            echo -e "${YELLOW}Sites disponibles :${NC}"
            ls -l "$WWW_DIR" | grep "^d" | awk '{print $9}'
            echo ""
            
            local site_name=$(get_user_input "Entrez le nom du site à sauvegarder" "" true)
            
            if [ -d "$WWW_DIR/$site_name" ]; then
                log_info "Sauvegarde du site $site_name..."
                local backup_file="$BACKUP_DIR/websites/${site_name}_$date_suffix.tar.gz"
                
                if tar -czf "$backup_file" "$WWW_DIR/$site_name"; then
                    show_success "Sauvegarde du site créée : $backup_file"
                else
                    show_error "Échec de la sauvegarde du site $site_name"
                fi
            else
                show_error "Le site $site_name n'existe pas"
            fi
            ;;
        0) return ;;
        *) 
            show_error "Option invalide"
            sleep 2
            ;;
    esac
    
    pause
}

# Fonction pour afficher les informations système
show_system_information() {
    show_header "Informations système"
    
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
        echo -e "${YELLOW}Sites actifs :${NC} $(ls -l $APACHE_ENABLED 2>/dev/null | grep -v ^total | wc -l)"
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
} 