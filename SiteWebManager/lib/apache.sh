#!/bin/bash

# Fonctions pour Apache
install_apache() {
    log_message "Installation d'Apache..."
    if sudo apt install apache2 -y; then
        echo -e "${GREEN}✓ Apache installé avec succès${NC}"
        sudo systemctl enable apache2
        echo -e "${GREEN}✓ Apache activé au démarrage${NC}"
    else
        log_error "Échec de l'installation d'Apache"
        return 1
    fi
}

start_apache() {
    log_message "Démarrage d'Apache..."
    if sudo systemctl start apache2; then
        echo -e "${GREEN}✓ Apache démarré avec succs${NC}"
    else
        log_error "Échec du démarrage d'Apache"
        return 1
    fi
}

stop_apache() {
    log_message "Arrêt d'Apache..."
    if sudo systemctl stop apache2; then
        echo -e "${GREEN}✓ Apache arrêté avec succès${NC}"
    else
        log_error "Échec de l'arrêt d'Apache"
        return 1
    fi
}

restart_apache() {
    log_message "Redémarrage d'Apache..."
    if sudo systemctl restart apache2; then
        echo -e "${GREEN}✓ Apache redémarré avec succès${NC}"
    else
        log_error "Échec du redémarrage d'Apache"
        return 1
    fi
}

status_apache() {
    echo -e "\n${BLUE}=== Statut d'Apache ===${NC}"
    if systemctl is-active --quiet apache2; then
        echo -e "${GREEN}✓ Apache est actif${NC}"
        echo -e "\n${YELLOW}Version d'Apache :${NC}"
        apache2 -v
        
        # Vérifier si netstat est installé
        if ! command -v netstat &> /dev/null; then
            echo -e "${YELLOW}Installation de net-tools...${NC}"
            sudo apt install net-tools -y
        fi
        
        # Vérifier si le module SSL est activé
        if ! apache2ctl -M | grep ssl_module > /dev/null; then
            echo -e "${YELLOW}Activation du module SSL...${NC}"
            sudo a2enmod ssl
            sudo systemctl restart apache2
            echo -e "${GREEN}✓ Module SSL activé${NC}"
        fi
        
        # Vérifier la configuration des hôtes virtuels
        echo -e "\n${YELLOW}Configuration des hôtes virtuels :${NC}"
        apache2ctl -S
        
        echo -e "\n${YELLOW}Ports en écoute :${NC}"
        echo -e "${GREEN}HTTP (80) et HTTPS (443) :${NC}"
        netstat -tuln | grep -E ":80|:443"
        
        echo -e "\n${YELLOW}Statut complet :${NC}"
        systemctl status apache2 | head -n 3
    else
        echo -e "${RED}✗ Apache n'est pas actif${NC}"
    fi
}

# Fonction pour configurer Apache
configure_apache() {
    while true; do
        clear
        show_bash_version
        echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║${NC}     ${GREEN}Configuration d'Apache${NC}               ${BLUE}║${NC}"
        echo -e "${BLUE}╠════════════════════════════════════════════╣${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[1]${NC} Éditer configuration principale     ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[2]${NC} Vérifier la syntaxe                ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[3]${NC} Gérer les modules                  ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[4]${NC} Gérer les sites virtuels           ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[5]${NC} Modifier le port SSH               ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[6]${NC} Autoriser ports Apache (80/443)    ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${RED}[0]${NC} Retour                              ${BLUE}║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
        
        read -p "$(echo -e ${YELLOW}Entrez votre choix [0-6]${NC}: )" config_choice

        case $config_choice in
            1) 
                sudo nano /etc/apache2/apache2.conf
                echo -e "${GREEN}✓ Configuration mise à jour${NC}"
                ;;
            2)
                echo -e "\n${YELLOW}Vérification de la syntaxe...${NC}"
                if sudo apache2ctl configtest; then
                    echo -e "${GREEN}✓ Syntaxe correcte${NC}"
                else
                    echo -e "${RED}✗ Erreurs détectées${NC}"
                fi
                ;;
            3)
                echo -e "\n${YELLOW}Modules actifs :${NC}"
                apache2ctl -M
                echo -e "\n${YELLOW}Voulez-vous activer/désactiver un module? (o/n)${NC}"
                read -r response
                if [[ "$response" =~ ^([oO][uU][iI]|[oO])$ ]]; then
                    read -p "Nom du module : " module_name
                    read -p "Activer (a) ou désactiver (d) ? " module_action
                    if [ "$module_action" = "a" ]; then
                        sudo a2enmod "$module_name"
                    elif [ "$module_action" = "d" ]; then
                        sudo a2dismod "$module_name"
                    fi
                    echo -e "${GREEN}✓ Action effectuée${NC}"
                fi
                ;;
            4)
                echo -e "\n${YELLOW}Sites disponibles :${NC}"
                ls -l /etc/apache2/sites-available/
                echo -e "\n${YELLOW}Sites activés :${NC}"
                ls -l /etc/apache2/sites-enabled/
                echo -e "\n${YELLOW}Voulez-vous activer/désactiver un site? (o/n)${NC}"
                read -r response
                if [[ "$response" =~ ^([oO][uU][iI]|[oO])$ ]]; then
                    read -p "Nom du fichier de configuration : " site_name
                    read -p "Activer (a) ou désactiver (d) ? " site_action
                    if [ "$site_action" = "a" ]; then
                        # Désactiver le site par défaut pour éviter les conflits
                        echo -e "${YELLOW}Désactivation du site par défaut...${NC}"
                        sudo a2dissite 000-default.conf
                        # Activer le site demandé
                        sudo a2ensite "$site_name"
                        echo -e "${GREEN}✓ Site activé${NC}"
                    elif [ "$site_action" = "d" ]; then
                        sudo a2dissite "$site_name"
                        echo -e "${GREEN}✓ Site désactivé${NC}"
                    fi
                    echo -e "\n${YELLOW}Vérification de la configuration des hôtes virtuels :${NC}"
                    apache2ctl -S
                fi
                ;;
            5)
                current_port=$(grep "^Port" /etc/ssh/sshd_config | awk '{print $2}')
                echo -e "\n${YELLOW}Port SSH actuel : ${NC}$current_port"
                
                read -p "$(echo -e ${YELLOW}Entrez le nouveau port SSH : ${NC})" new_port
                
                if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
                    sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
                    
                    if sudo sed -i "s/^Port .*$/Port $new_port/" /etc/ssh/sshd_config; then
                        echo -e "${GREEN}✓ Port SSH modifié avec succès${NC}"
                        echo -e "${YELLOW}Redémarrage du service SSH...${NC}"
                        if sudo systemctl restart ssh; then
                            echo -e "${GREEN}✓ Service SSH redémarré${NC}"
                            echo -e "\n${RED}IMPORTANT : Notez le nouveau port SSH : $new_port${NC}"
                            echo -e "${RED}Utilisez ce port pour votre prochaine connexion SSH${NC}"
                        else
                            echo -e "${RED}✗ Échec du redémarrage SSH${NC}"
                            echo -e "${YELLOW}Restauration de la configuration précédente...${NC}"
                            sudo cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
                            sudo systemctl restart ssh
                        fi
                    else
                        log_error "Échec de la modification du port"
                    fi
                else
                    log_error "Port invalide. Veuillez entrer un nombre entre 1 et 65535"
                fi
                ;;
            6)
                echo -e "\n${YELLOW}Configuration des ports Apache...${NC}"
                if sudo ufw allow 'Apache Full'; then
                    echo -e "${GREEN}✓ Ports HTTP (80) et HTTPS (443) autorisés avec succès${NC}"
                    echo -e "\n${YELLOW}Statut des règles Apache dans UFW :${NC}"
                    sudo ufw status | grep Apache
                else
                    log_error "Échec de l'autorisation des ports Apache"
                fi
                ;;
            0) return ;;
            *)
                echo -e "${RED}Option invalide${NC}"
                sleep 2
                ;;
        esac
        
        if [ "$config_choice" != "0" ]; then
            echo -e "\n${YELLOW}Appuyez sur Entrée pour continuer...${NC}"
            read -r
        fi
    done
} 