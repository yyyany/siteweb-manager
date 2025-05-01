#!/bin/bash
# Fonctions de gestion des menus

# Menu principal
show_main_menu() {
    while true; do
        show_header
        
        local options=(
            "Gestion des sites web"
            "Gestion des bases de données"
            "Gestion de PHP"
            "Gestion du système"
            "Configuration"
            "Aide"
        )
        
        show_menu "Menu Principal" "${options[@]}"
        
        read -p "Votre choix : " choice
        
        case $choice in
            1) show_sites_menu;;
            2) show_database_menu;;
            3) show_php_menu;;
            4) show_system_menu;;
            5) show_config_menu;;
            6) show_help;;
            0) break;;
            *) show_error "Choix invalide";;
        esac
    done
}

# Menu de gestion des sites web
show_sites_menu() {
    while true; do
        show_header
        
        local options=(
            "Déployer un site"
            "Lister les sites"
            "Supprimer un site"
            "Vérifier un site"
            "Réparer un site"
        )
        
        show_menu "Gestion des Sites Web" "${options[@]}"
        
        read -p "Votre choix : " choice
        
        case $choice in
            1)
                show_header
                echo -e "${BLUE}=== Déploiement d'un site web ===${NC}"
                echo
                echo -e "${CYAN}Cette fonction vous permet de déployer un site web sur votre serveur.${NC}"
                echo -e "${CYAN}Vous devez spécifier :${NC}"
                echo -e "  ${YELLOW}1. Le chemin du répertoire source${NC} - où se trouvent vos fichiers HTML/CSS/JS"
                echo -e "  ${YELLOW}2. Le nom de domaine${NC} - exemple: monsite.com"
                echo
                echo -e "${CYAN}Conseils :${NC}"
                echo -e "  - Le répertoire source doit exister et contenir vos fichiers web"
                echo -e "  - Le nom de domaine doit être valide (format: exemple.com)"
                echo -e "  - Assurez-vous que votre DNS est configuré pour pointer vers ce serveur"
                echo

                read -p "Chemin du répertoire source (ex: /home/utilisateur/mon-site) : " source_dir
                if [[ -z "$source_dir" ]]; then
                    show_error "Le chemin du répertoire source ne peut pas être vide"
                    read -p "Appuyez sur Entrée pour continuer..."
                    continue
                fi
                
                if [[ ! -d "$source_dir" ]]; then
                    show_error "Le répertoire '$source_dir' n'existe pas"
                    echo -e "${YELLOW}Conseil: Utilisez un chemin absolu et vérifiez que le répertoire existe${NC}"
                    read -p "Appuyez sur Entrée pour continuer..."
                    continue
                fi

                read -p "Nom de domaine (ex: exemple.com) : " domain
                if [[ -z "$domain" ]]; then
                    show_error "Le nom de domaine ne peut pas être vide"
                    read -p "Appuyez sur Entrée pour continuer..."
                    continue
                fi
                
                # Confirmation avec récapitulatif
                echo
                echo -e "${BLUE}=== Récapitulatif ===${NC}"
                echo -e "${YELLOW}Répertoire source :${NC} $source_dir"
                echo -e "${YELLOW}Nom de domaine :${NC} $domain"
                echo -e "${YELLOW}Destination :${NC} $WWW_DIR/$domain"
                echo
                
                if show_confirm "Voulez-vous déployer ce site?" "y"; then
                    deploy_site "$source_dir" "$domain"
                else
                    show_info "Déploiement annulé"
                    read -p "Appuyez sur Entrée pour continuer..."
                fi
                ;;
            2) list_sites;;
            3)
                show_header
                echo -e "${BLUE}=== Suppression d'un site web ===${NC}"
                echo
                echo -e "${CYAN}Cette fonction permet de supprimer un site web et sa configuration.${NC}"
                echo -e "${CYAN}Attention: Cette action est irréversible!${NC}"
                echo
                
                # Afficher les sites disponibles
                echo -e "${YELLOW}Sites disponibles :${NC}"
                ls -1 "$APACHE_AVAILABLE" | grep -v "000-default.conf" | sed 's/\.conf$//' || echo "Aucun site disponible"
                echo
                
                read -p "Nom de domaine à supprimer : " domain
                
                if [[ -z "$domain" ]]; then
                    show_error "Le nom de domaine ne peut pas être vide"
                    read -p "Appuyez sur Entrée pour continuer..."
                    continue
                fi
                
                if ! show_confirm "Êtes-vous sûr de vouloir supprimer le site $domain?" "n"; then
                    show_info "Suppression annulée"
                    read -p "Appuyez sur Entrée pour continuer..."
                    continue
                fi
                
                remove_site "$domain"
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
            4)
                show_header
                echo -e "${BLUE}=== Vérification d'un site web ===${NC}"
                echo
                echo -e "${CYAN}Cette fonction vérifie l'état d'un site web déployé.${NC}"
                echo
                
                # Afficher les sites disponibles
                echo -e "${YELLOW}Sites disponibles :${NC}"
                ls -1 "$APACHE_AVAILABLE" | grep -v "000-default.conf" | sed 's/\.conf$//' || echo "Aucun site disponible"
                echo
                
                read -p "Nom de domaine à vérifier : " domain
                
                if [[ -z "$domain" ]]; then
                    show_error "Le nom de domaine ne peut pas être vide"
                    read -p "Appuyez sur Entrée pour continuer..."
                    continue
                fi
                
                check_site "$domain"
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
            5)
                show_header
                echo -e "${BLUE}=== Réparation d'un site web ===${NC}"
                echo
                echo -e "${CYAN}Cette fonction tente de réparer un site web qui ne fonctionne pas correctement.${NC}"
                echo -e "${CYAN}Elle reconfigure les permissions, réactive le site et redémarre Apache.${NC}"
                echo
                
                # Afficher les sites disponibles
                echo -e "${YELLOW}Sites disponibles :${NC}"
                ls -1 "$WWW_DIR" | grep -v "html" || echo "Aucun site déployé"
                echo
                
                read -p "Nom de domaine à réparer : " domain
                
                if [[ -z "$domain" ]]; then
                    show_error "Le nom de domaine ne peut pas être vide"
                    read -p "Appuyez sur Entrée pour continuer..."
                    continue
                fi
                
                repair_site "$domain"
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
            0) break;;
            *) 
                show_error "Choix invalide"
                read -p "Appuyez sur Entrée pour continuer..."
                ;;
        esac
    done
}

# Menu de gestion des bases de données
show_database_menu() {
    while true; do
        show_header
        
        local options=(
            "Installer MariaDB"
            "Créer une base de données"
            "Lister les bases de données"
            "Supprimer une base de données"
            "Sauvegarder une base de données"
            "Restaurer une base de données"
        )
        
        show_menu "Gestion des Bases de Données" "${options[@]}"
        
        read -p "Votre choix : " choice
        
        case $choice in
            1) install_mariadb;;
            2)
                read -p "Nom de la base de données : " db_name
                read -p "Nom d'utilisateur : " db_user
                read -p "Mot de passe : " db_password
                create_database "$db_name" "$db_user" "$db_password"
                ;;
            3) list_databases;;
            4)
                read -p "Nom de la base de données à supprimer : " db_name
                drop_database "$db_name"
                ;;
            5)
                read -p "Nom de la base de données à sauvegarder : " db_name
                read -p "Répertoire de sauvegarde (optionnel) : " backup_dir
                backup_database "$db_name" "$backup_dir"
                ;;
            6)
                read -p "Nom de la base de données à restaurer : " db_name
                read -p "Chemin du fichier de sauvegarde : " backup_file
                restore_database "$db_name" "$backup_file"
                ;;
            0) break;;
            *) show_error "Choix invalide";;
        esac
    done
}

# Menu de gestion de PHP
show_php_menu() {
    while true; do
        show_header
        
        local options=(
            "Installer PHP"
            "Installer Composer"
            "Installer une extension"
            "Vérifier la version"
            "Optimiser les performances"
        )
        
        show_menu "Gestion de PHP" "${options[@]}"
        
        read -p "Votre choix : " choice
        
        case $choice in
            1)
                read -p "Version de PHP (8.2 par défaut) : " php_version
                install_php "$php_version"
                ;;
            2) install_composer;;
            3)
                read -p "Nom de l'extension : " extension
                read -p "Version de PHP (8.2 par défaut) : " php_version
                install_php_extension "$extension" "$php_version"
                ;;
            4)
                read -p "Version de PHP à vérifier (8.2 par défaut) : " php_version
                check_php_version "$php_version"
                ;;
            5)
                read -p "Version de PHP à optimiser (8.2 par défaut) : " php_version
                optimize_php "$php_version"
                ;;
            0) break;;
            *) show_error "Choix invalide";;
        esac
    done
}

# Menu de gestion du système
show_system_menu() {
    while true; do
        show_header
        
        local options=(
            "Mettre à jour le système"
            "Configurer le pare-feu"
            "Afficher les informations système"
        )
        
        show_menu "Gestion du Système" "${options[@]}"
        
        read -p "Votre choix : " choice
        
        case $choice in
            1) update_system;;
            2) configure_firewall;;
            3) show_system_info;;
            0) break;;
            *) show_error "Choix invalide";;
        esac
    done
}

# Menu de configuration
show_config_menu() {
    while true; do
        show_header
        
        local options=(
            "Afficher la configuration actuelle"
            "Modifier les paramètres"
            "Restaurer les paramètres par défaut"
        )
        
        show_menu "Configuration" "${options[@]}"
        
        read -p "Votre choix : " choice
        
        case $choice in
            1)
                echo -e "${BLUE}=== Configuration Actuelle ===${NC}"
                cat "$CONFIG_FILE"
                ;;
            2)
                read -p "Paramètre à modifier : " param
                read -p "Nouvelle valeur : " value
                sed -i "s/^$param=.*/$param=$value/" "$CONFIG_FILE"
                show_success "Paramètre modifié avec succès"
                ;;
            3)
                if show_confirm "Êtes-vous sûr de vouloir restaurer les paramètres par défaut ?"; then
                    cp "$CONFIG_FILE.default" "$CONFIG_FILE"
                    show_success "Configuration restaurée avec succès"
                fi
                ;;
            0) break;;
            *) show_error "Choix invalide";;
        esac
    done
}

# Afficher l'aide
show_help() {
    show_header
    
    echo -e "${BLUE}=== Aide ===${NC}"
    echo
    echo "SiteWeb Manager est un outil de gestion de sites web et de services associés."
    echo
    echo "Fonctionnalités principales :"
    echo "- Gestion des sites web (déploiement, vérification, réparation)"
    echo "- Gestion des bases de données MariaDB"
    echo "- Gestion de PHP et des extensions"
    echo "- Gestion du système (mises à jour, pare-feu)"
    echo "- Configuration personnalisable"
    echo
    echo "Pour plus d'informations, consultez la documentation."
    echo
    read -p "Appuyez sur Entrée pour continuer..."
} 