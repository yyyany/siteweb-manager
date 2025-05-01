#!/bin/bash

# Vérifier si les chemins exportés sont disponibles
if [ -z "$BASE_DIR" ]; then
    # Si non, déterminer le chemin absolu
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    if [[ "$SCRIPT_DIR" == */ui ]]; then
        BASE_DIR="$(dirname "$SCRIPT_DIR")"
    elif [[ "$SCRIPT_DIR" == */siteweb-manager/SiteWebManager/ui ]]; then
        BASE_DIR="$(dirname "$SCRIPT_DIR")"
    elif [ -d "/home/ubuntu/siteweb-manager/SiteWebManager" ]; then
        BASE_DIR="/home/ubuntu/siteweb-manager/SiteWebManager"
    else
        echo "ERREUR: Impossible de déterminer le chemin de base depuis menus.sh. Chemin actuel: $SCRIPT_DIR"
        exit 1
    fi
    
    # Définir et exporter les chemins vers les modules
    CONFIG_FILE="$BASE_DIR/config/config.sh"
    UTILS_FILE="$BASE_DIR/lib/utils.sh"
    SYSTEM_FILE="$BASE_DIR/lib/system.sh"
    APACHE_FILE="$BASE_DIR/lib/apache.sh"
    SITES_FILE="$BASE_DIR/lib/sites.sh"
    SSL_FILE="$BASE_DIR/lib/ssl.sh"
    MENUS_FILE="$BASE_DIR/ui/menus.sh"
    
    # Charger ces modules s'ils ne sont pas déjà chargés
    for file in "$CONFIG_FILE" "$UTILS_FILE" "$SYSTEM_FILE" "$APACHE_FILE" "$SITES_FILE" "$SSL_FILE"; do
        if [ -f "$file" ]; then
            # Vérifier si le fichier a déjà été chargé
            filename=$(basename "$file")
            if ! declare -f | grep -q "$(basename "$file" .sh)"; then
                echo "Chargement de $filename depuis menus.sh..."
                source "$file"
            fi
        else
            echo "ERREUR: Fichier non trouvé: $file"
        fi
    done
fi

# Enregistrer les fonctions disponibles pour déboguer
if [ "$DEBUG" = "1" ]; then
    echo "Fonctions disponibles dans menus.sh:"
    declare -F | grep -v '^declare -f _' | sed 's/declare -f //'
fi

# Menu de gestion des sites
manage_sites() {
    while true; do
        clear
        show_bash_version
        echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║${NC}        ${GREEN}Gestion des Sites Web${NC}              ${BLUE}║${NC}"
        echo -e "${BLUE}╠════════════════════════════════════════════╣${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[1]${NC} Déployer un nouveau site            ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[2]${NC} Liste des sites déployés            ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[3]${NC} Supprimer un site                   ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[4]${NC} Configurer HTTPS                    ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[5]${NC} Vérifier/Réparer un site            ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[6]${NC} Diagnostic SSL/HTTPS                ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[7]${NC} Vérifier les DNS                    ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[8]${NC} Vérifier config hôtes virtuels      ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${RED}[0]${NC} Retour                              ${BLUE}║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
        
        read -p "$(echo -e ${YELLOW}Entrez votre choix [0-8]${NC}: )" site_choice

        case $site_choice in
            1) deploy_site ;;
            2)
                echo -e "\n${YELLOW}Sites disponibles :${NC}"
                ls -l /etc/apache2/sites-available/
                echo -e "\n${YELLOW}Sites activés :${NC}"
                ls -l /etc/apache2/sites-enabled/
                ;;
            3)
                clear
                echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
                echo -e "${BLUE}║${NC}        ${GREEN}Suppression d'un Site${NC}              ${BLUE}║${NC}"
                echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

                echo -e "${YELLOW}Sites disponibles :${NC}\n"
                
                # Liste simple des sites
                num=1
                declare -a site_list
                
                for site in /etc/apache2/sites-available/*.conf; do
                    site_name=$(basename "$site")
                    if [ "$site_name" != "000-default.conf" ] && [ "$site_name" != "default-ssl.conf" ]; then
                        site_list[$num]=$site_name
                        if [ -L "/etc/apache2/sites-enabled/$site_name" ]; then
                            status="${GREEN}(activé)${NC}"
                        else
                            status="${RED}(désactivé)${NC}"
                        fi
                        echo -e "${YELLOW}[$num]${NC} $site_name $status"
                        num=$((num + 1))
                    fi
                done

                if [ $num -eq 1 ]; then
                    echo -e "${RED}Aucun site personnalisé trouvé${NC}"
                    read -p "Appuyez sur Entrée pour continuer..."
                    continue
                fi

                echo -e "${RED}[0]${NC} Annuler\n"
                read -p "Choisissez le numéro du site à supprimer [0-$((num-1))] : " choice

                if [ "$choice" = "0" ]; then
                    echo -e "${YELLOW}Suppression annulée${NC}"
                    continue
                fi

                if [ "$choice" -gt 0 ] && [ "$choice" -lt "$num" ]; then
                    selected_site=${site_list[$choice]}
                    site_name=${selected_site%.conf}

                    echo -e "\n${RED}Attention! Vous allez supprimer le site : $selected_site${NC}"
                    read -p "Êtes-vous sûr ? (o/n) : " confirm

                    if [ "$confirm" = "o" ] || [ "$confirm" = "O" ]; then
                        if [ -L "/etc/apache2/sites-enabled/$selected_site" ]; then
                            sudo a2dissite "$selected_site"
                        fi
                        sudo rm "/etc/apache2/sites-available/$selected_site"
                        sudo rm -rf "/var/www/$site_name"
                        sudo systemctl restart apache2
                        echo -e "${GREEN}Site supprimé avec succès${NC}"
                    else
                        echo -e "${YELLOW}Suppression annulée${NC}"
                    fi
                else
                    echo -e "${RED}Numéro invalide${NC}"
                fi
                ;;
            4) configure_https ;;
            5) check_repair_site ;;
            6) diagnose_ssl ;;
            7) 
                read -p "Entrez le nom de domaine à vérifier : " domain_to_check
                check_dns "$domain_to_check"
                ;;
            8)
                echo -e "\n${YELLOW}Configuration des hôtes virtuels Apache :${NC}"
                apache2ctl -S
                ;;
            0) return ;;
            *)
                echo -e "${RED}Option invalide${NC}"
                sleep 2
                ;;
        esac
        
        if [ "$site_choice" != "0" ]; then
            echo -e "\n${YELLOW}Appuyez sur Entrée pour continuer...${NC}"
            read -r
        fi
    done
}

# Menu principal d'Apache
apache_menu() {
    while true; do
        clear
        show_bash_version
        echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║${NC}        ${GREEN}Gestion d'Apache${NC}                   ${BLUE}║${NC}"
        echo -e "${BLUE}╠════════════════════════════════════════════╣${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[1]${NC} Installer Apache                     ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[2]${NC} Démarrer Apache                     ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[3]${NC} Arrêter Apache                      ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[4]${NC} Redémarrer Apache                   ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[5]${NC} Statut Apache                       ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[6]${NC} Configuration Apache                 ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[7]${NC} Désactiver site par défaut          ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${RED}[0]${NC} Retour au menu principal            ${BLUE}║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
        
        read -p "$(echo -e ${YELLOW}Entrez votre choix [0-7]${NC}: )" apache_choice

        case $apache_choice in
            1) install_apache ;;
            2) start_apache ;;
            3) stop_apache ;;
            4) restart_apache ;;
            5) status_apache ;;
            6) configure_apache ;;
            7)
                echo -e "\n${YELLOW}Désactivation du site par défaut...${NC}"
                if [ -f "/etc/apache2/sites-enabled/000-default.conf" ]; then
                    sudo a2dissite 000-default.conf
                    sudo systemctl restart apache2
                    echo -e "${GREEN}✓ Site par défaut désactivé${NC}"
                    echo -e "\n${YELLOW}Configuration des hôtes virtuels mise à jour :${NC}"
                    apache2ctl -S
                else
                    echo -e "${GREEN}✓ Site par défaut déjà désactivé${NC}"
                fi
                ;;
            0) return ;;
            *)
                echo -e "${RED}Option invalide, veuillez réessayer.${NC}"
                sleep 2
                ;;
        esac
        
        if [ "$apache_choice" != "0" ]; then
            echo -e "\n${YELLOW}Appuyez sur Entrée pour retourner au menu Apache...${NC}"
            read -r
        fi
    done
}

# Fonction pour afficher le menu et gérer la sélection
show_menu() {
    while true; do
        clear
        show_bash_version
        echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║${NC}     ${GREEN}Gestion de la VM DigitalOcean${NC}         ${BLUE}║${NC}"
        echo -e "${BLUE}╠════════════════════════════════════════════╣${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[1]${NC} Mise à jour de linux                ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[2]${NC} Installation Apache                  ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[3]${NC} Gestion des sites web               ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[4]${NC} Informations système                ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[5]${NC} Coucou mon ami Skandysan           ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${RED}[0]${NC} Quitter                              ${BLUE}║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
        echo -e "\n${GREEN}Serveur${NC}: $(hostname) | ${GREEN}IP${NC}: $(hostname -I | cut -d' ' -f1)"
        echo -e "${GREEN}Date${NC}: $(date '+%Y-%m-%d %H:%M:%S')\n"
        
        read -p "$(echo -e ${YELLOW}Entrez votre choix [0-5]${NC}: )" choice

        case $choice in
            1) update_linux ;;
            2) apache_menu ;;
            3) manage_sites ;;
            4) echo "Option 4 sélectionnée" ;;
            5) echo "Option 5 sélectionnée" ;;
            0)
                clear
                echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
                echo -e "${GREEN}║${NC}      Merci d'avoir utilisé ce script!      ${GREEN}║${NC}"
                echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Option invalide, veuillez réessayer.${NC}"
                sleep 2
                ;;
        esac
        
        if [ "$choice" != "0" ]; then
            echo -e "\n${YELLOW}Appuyez sur Entrée pour retourner au menu...${NC}"
            read -r
        fi
    done
} 