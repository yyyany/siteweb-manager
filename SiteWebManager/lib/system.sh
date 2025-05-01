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