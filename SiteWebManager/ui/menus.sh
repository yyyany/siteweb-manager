#!/bin/bash
# Module de gestion des menus

# Menu principal
show_main_menu() {
    while true; do
        show_menu "Menu Principal" \
            "Mise à jour du système" \
            "Gestion d'Apache" \
            "Gestion des sites web" \
            "Gestion de PHP" \
            "Gestion des bases de données" \
            "Informations système" \
            "Configuration et sécurité" \
            "quit"
        
        choice=$(get_user_choice "Entrez votre choix" 7)
        
        case $choice in
            1) system_update_menu ;;
            2) apache_menu ;;
            3) sites_menu ;;
            4) php_menu ;;
            5) database_menu ;;
            6) show_system_info; pause ;;
            7) security_menu ;;
            0) 
                show_header "Au revoir!"
                log_info "Fin du programme"
                exit 0 
                ;;
            *) 
                show_error "Option invalide"
                sleep 2
                ;;
        esac
    done
}

# Menu de mise à jour du système
system_update_menu() {
    show_menu "Mise à jour du système" \
        "Mettre à jour la liste des paquets" \
        "Mettre à jour tous les paquets" \
        "Mettre à jour et nettoyer le système" \
        "Gérer les paquets installés" \
        "back"
    
    choice=$(get_user_choice "Entrez votre choix" 4)
    
    case $choice in
        1) 
            log_info "Mise à jour de la liste des paquets..."
            update_package_list
            pause
            ;;
        2) 
            log_info "Mise à jour des paquets..."
            upgrade_packages
            pause
            ;;
        3) 
            log_info "Mise à jour complète du système..."
            update_system
            pause
            ;;
        4) 
            log_info "Gestion des paquets installés..."
            manage_packages
            ;;
        0) return ;;
        *) 
            show_error "Option invalide"
            sleep 2
            system_update_menu
            ;;
    esac
}

# Menu de gestion d'Apache
apache_menu() {
    while true; do
        show_menu "Gestion d'Apache" \
            "Installer Apache" \
            "Démarrer Apache" \
            "Arrêter Apache" \
            "Redémarrer Apache" \
            "Statut Apache" \
            "Configuration Apache" \
            "Gestion des modules" \
            "back"
        
        choice=$(get_user_choice "Entrez votre choix" 7)
        
        case $choice in
            1) 
                log_info "Installation d'Apache..."
                install_apache
                pause
                ;;
            2) 
                log_info "Démarrage d'Apache..."
                start_apache
                pause
                ;;
            3) 
                log_info "Arrêt d'Apache..."
                stop_apache
                pause
                ;;
            4) 
                log_info "Redémarrage d'Apache..."
                restart_apache
                pause
                ;;
            5) 
                log_info "Affichage du statut d'Apache..."
                status_apache
                pause
                ;;
            6) apache_config_menu ;;
            7) apache_modules_menu ;;
            0) return ;;
            *) 
                show_error "Option invalide"
                sleep 2
                ;;
        esac
    done
}

# Menu de configuration d'Apache
apache_config_menu() {
    while true; do
        show_menu "Configuration d'Apache" \
            "Éditer configuration principale" \
            "Vérifier la syntaxe" \
            "Configurer le pare-feu" \
            "Configurer les ports" \
            "Optimiser les performances" \
            "Sécuriser Apache" \
            "back"
        
        choice=$(get_user_choice "Entrez votre choix" 6)
        
        case $choice in
            1) 
                log_info "Édition de la configuration principale..."
                edit_apache_config
                pause
                ;;
            2) 
                log_info "Vérification de la syntaxe..."
                check_apache_config
                pause
                ;;
            3) 
                log_info "Configuration du pare-feu..."
                configure_apache_firewall
                pause
                ;;
            4) 
                log_info "Configuration des ports..."
                configure_apache_ports
                pause
                ;;
            5) 
                log_info "Optimisation des performances..."
                optimize_apache
                pause
                ;;
            6) 
                log_info "Sécurisation d'Apache..."
                secure_apache
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

# Menu de gestion des modules Apache
apache_modules_menu() {
    while true; do
        show_menu "Gestion des modules Apache" \
            "Lister les modules actifs" \
            "Activer un module" \
            "Désactiver un module" \
            "back"
        
        choice=$(get_user_choice "Entrez votre choix" 3)
        
        case $choice in
            1) 
                log_info "Liste des modules actifs..."
                list_apache_modules
                pause
                ;;
            2) 
                log_info "Activation d'un module..."
                enable_apache_module
                pause
                ;;
            3) 
                log_info "Désactivation d'un module..."
                disable_apache_module
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

# Menu de gestion des sites web
sites_menu() {
    while true; do
        show_menu "Gestion des sites web" \
            "Déployer un nouveau site" \
            "Liste des sites déployés" \
            "Supprimer un site" \
            "Configurer HTTPS (SSL)" \
            "Vérifier/Réparer un site" \
            "Diagnostic DNS" \
            "back"
        
        choice=$(get_user_choice "Entrez votre choix" 6)
        
        case $choice in
            1) 
                log_info "Déploiement d'un nouveau site..."
                deploy_site
                pause
                ;;
            2) 
                log_info "Liste des sites déployés..."
                list_sites
                pause
                ;;
            3) 
                log_info "Suppression d'un site..."
                delete_site
                pause
                ;;
            4) 
                log_info "Configuration HTTPS..."
                ssl_menu
                ;;
            5) 
                log_info "Vérification/Réparation d'un site..."
                check_repair_site
                pause
                ;;
            6) 
                log_info "Diagnostic DNS..."
                check_dns_menu
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

# Menu SSL/HTTPS
ssl_menu() {
    while true; do
        show_menu "Configuration SSL/HTTPS" \
            "Configurer HTTPS pour un site" \
            "Renouveler un certificat" \
            "Vérifier les certificats existants" \
            "Diagnostic SSL" \
            "back"
        
        choice=$(get_user_choice "Entrez votre choix" 4)
        
        case $choice in
            1) 
                log_info "Configuration HTTPS pour un site..."
                configure_https
                pause
                ;;
            2) 
                log_info "Renouvellement d'un certificat..."
                renew_certificate
                pause
                ;;
            3) 
                log_info "Vérification des certificats existants..."
                list_certificates
                pause
                ;;
            4) 
                log_info "Diagnostic SSL..."
                diagnose_ssl
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

# Menu de vérification DNS
check_dns_menu() {
    show_header "Vérification DNS"
    
    domain=$(get_user_input "Entrez le nom de domaine à vérifier" "" true)
    
    if validate_domain "$domain"; then
        check_dns "$domain"
    else
        show_error "Nom de domaine invalide: $domain"
    fi
}

# Menu de gestion de PHP
php_menu() {
    while true; do
        show_menu "Gestion de PHP" \
            "Installer PHP" \
            "Mettre à jour PHP" \
            "Configurer PHP" \
            "Gérer les extensions PHP" \
            "Installer plusieurs versions de PHP" \
            "Changer la version PHP par défaut" \
            "back"
        
        choice=$(get_user_choice "Entrez votre choix" 6)
        
        case $choice in
            1) 
                log_info "Installation de PHP..."
                php_install_menu
                ;;
            2) 
                log_info "Mise à jour de PHP..."
                update_php
                pause
                ;;
            3) 
                log_info "Configuration de PHP..."
                php_config_menu
                ;;
            4) 
                log_info "Gestion des extensions PHP..."
                php_extensions_menu
                ;;
            5) 
                log_info "Installation de plusieurs versions de PHP..."
                install_multiple_php
                pause
                ;;
            6) 
                log_info "Changement de la version PHP par défaut..."
                switch_php_version
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

# Menu d'installation de PHP
php_install_menu() {
    show_header "Installation de PHP"
    
    # Afficher les versions disponibles
    show_info "Versions de PHP disponibles:"
    echo -e "1. PHP 7.4 (stable)"
    echo -e "2. PHP 8.0"
    echo -e "3. PHP 8.1 (récent)"
    echo -e "0. Annuler"
    echo ""
    
    choice=$(get_user_choice "Choisissez la version à installer" 3)
    
    case $choice in
        1) 
            version="7.4"
            install_php "$version"
            ;;
        2) 
            version="8.0"
            install_php "$version"
            ;;
        3) 
            version="8.1"
            install_php "$version"
            ;;
        0) return ;;
        *) 
            show_error "Option invalide"
            sleep 2
            php_install_menu
            ;;
    esac
    
    pause
}

# Menu de configuration PHP
php_config_menu() {
    while true; do
        show_menu "Configuration PHP" \
            "Afficher la configuration actuelle" \
            "Modifier php.ini" \
            "Configurer les limites (mémoire, upload)" \
            "Configurer le timezone" \
            "back"
        
        choice=$(get_user_choice "Entrez votre choix" 4)
        
        case $choice in
            1) 
                log_info "Affichage de la configuration PHP actuelle..."
                show_php_config
                pause
                ;;
            2) 
                log_info "Modification du php.ini..."
                edit_php_ini
                pause
                ;;
            3) 
                log_info "Configuration des limites PHP..."
                configure_php_limits
                pause
                ;;
            4) 
                log_info "Configuration du timezone PHP..."
                configure_php_timezone
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

# Menu de gestion des bases de données
database_menu() {
    while true; do
        show_menu "Gestion des bases de données" \
            "Installer MariaDB/MySQL" \
            "Démarrer le service de base de données" \
            "Arrêter le service de base de données" \
            "Créer une base de données" \
            "Créer un utilisateur" \
            "Lister les bases de données" \
            "Exporter/Importer une base de données" \
            "Sécuriser l'installation" \
            "back"
        
        choice=$(get_user_choice "Entrez votre choix" 8)
        
        case $choice in
            1) 
                log_info "Installation de MariaDB/MySQL..."
                install_db
                pause
                ;;
            2) 
                log_info "Démarrage du service de base de données..."
                start_db
                pause
                ;;
            3) 
                log_info "Arrêt du service de base de données..."
                stop_db
                pause
                ;;
            4) 
                log_info "Création d'une base de données..."
                create_database_menu
                ;;
            5) 
                log_info "Création d'un utilisateur..."
                create_db_user_menu
                ;;
            6) 
                log_info "Liste des bases de données..."
                list_databases
                pause
                ;;
            7) 
                log_info "Export/Import de base de données..."
                db_export_import_menu
                ;;
            8) 
                log_info "Sécurisation de l'installation..."
                secure_db
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

# Menu de sécurité et configuration
security_menu() {
    while true; do
        show_menu "Configuration et sécurité" \
            "Configurer SSH" \
            "Configurer le pare-feu (UFW)" \
            "Mettre à jour les règles de sécurité" \
            "Analyser les journaux" \
            "Configurer les sauvegardes" \
            "back"
        
        choice=$(get_user_choice "Entrez votre choix" 5)
        
        case $choice in
            1) 
                log_info "Configuration SSH..."
                configure_ssh_menu
                ;;
            2) 
                log_info "Configuration du pare-feu..."
                configure_firewall_menu
                ;;
            3) 
                log_info "Mise à jour des règles de sécurité..."
                update_security
                pause
                ;;
            4) 
                log_info "Analyse des journaux..."
                analyze_logs
                pause
                ;;
            5) 
                log_info "Configuration des sauvegardes..."
                configure_backups
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

# Fonction pour exécuter les menus supplémentaires au besoin
run_menu() {
    local menu_name="$1"
    local menu_function="show_${menu_name}_menu"
    
    # Vérifier si la fonction de menu existe
    if declare -f "$menu_function" > /dev/null; then
        "$menu_function"
    else
        show_error "Menu $menu_name non trouvé"
        sleep 2
    fi
} 