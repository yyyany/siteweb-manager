#!/bin/bash
# Version du script
VERSION="1.21"
# Historique des versions
# 1.00 - Version initiale
# 1.01 - Ajout de l'installation automatique de net-tools
# 1.02 - Ajout de la vérification et activation automatique du module SSL
# 1.03 - Standardisation des menus avec '0' comme touche de retour/quitter
# mdp : EcoleDuWebRoot!
# Définition des couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour les messages de log
log_message() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Fonction pour les messages d'erreur
log_error() {
    echo -e "${RED}[ERREUR] $1${NC}"
}

# Fonction pour mettre à jour le système Linux
update_linux() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}        ${GREEN}Mise à jour du système${NC}             ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

    log_message "Début de la mise à jour du système..."
    
    # Mise à jour de la liste des paquets
    log_message "Mise à jour de la liste des paquets..."
    if sudo apt update; then
        echo -e "${GREEN}✓ Liste des paquets mise à jour avec succès${NC}"
    else
        log_error "Échec de la mise à jour de la liste des paquets"
        return 1
    fi

    # Mise à niveau des paquets
    log_message "Installation des mises à jour..."
    if sudo apt upgrade -y; then
        echo -e "${GREEN}✓ Système mis à jour avec succès${NC}"
    else
        log_error "Échec de la mise à jour du système"
        return 1
    fi

    # Nettoyage
    log_message "Nettoyage des paquets obsolètes..."
    if sudo apt autoremove -y && sudo apt clean; then
        echo -e "${GREEN}✓ Nettoyage terminé avec succès${NC}"
    else
        log_error "Échec du nettoyage"
        return 1
    fi

    echo -e "\n${GREEN}✓ Mise à jour du système terminée${NC}"
}

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
        
        echo -e "\n${YELLOW}Ports en écoute :${NC}"
        echo -e "${GREEN}HTTP (80) et HTTPS (443) :${NC}"
        netstat -tuln | grep -E ":80|:443"
        
        echo -e "\n${YELLOW}Statut complet :${NC}"
        systemctl status apache2 | head -n 3
    else
        echo -e "${RED}✗ Apache n'est pas actif${NC}"
    fi
}

# Fonction pour afficher la version de bash
show_bash_version() {
    local bash_version=$(bash --version | head -n1)
    echo -e "${BLUE}Version du script : ${NC}v${VERSION}"
    echo -e "${BLUE}Version Bash : ${NC}$bash_version"
    echo -e "${BLUE}Date : ${NC}$(date '+%Y-%m-%d %H:%M:%S')\n"
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
                        sudo a2ensite "$site_name"
                    elif [ "$site_action" = "d" ]; then
                        sudo a2dissite "$site_name"
                    fi
                    echo -e "${GREEN}✓ Action effectuée${NC}"
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

# Fonction pour déployer un site
deploy_site() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}        ${GREEN}Déploiement d'un Site Web${NC}          ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

    # Demander comment sélectionner le dossier
    echo -e "${YELLOW}Comment voulez-vous sélectionner le dossier du site?${NC}"
    echo -e "${YELLOW}[1]${NC} Sélectionner parmi les dossiers disponibles"
    echo -e "${YELLOW}[2]${NC} Spécifier manuellement le chemin complet du dossier"
    read -p "$(echo -e ${YELLOW}Votre choix [1-2]${NC}: )" selection_choice
    
    site_name=""
    
    if [ "$selection_choice" = "1" ]; then
        # Option 1: Lister les dossiers disponibles
        echo -e "\n${YELLOW}Dossiers disponibles (ceux contenant un index.html ou index.php sont marqués avec *) :${NC}"
        
        # Trouver tous les dossiers du répertoire courant
        folders=()
        i=1
        
        # Pour chaque dossier dans le répertoire courant
        for folder in */; do
            folder=${folder%/} # Enlever le slash final
            
            # Vérifier si le dossier contient un fichier index.html ou index.php
            if [ -f "$folder/index.html" ] || [ -f "$folder/index.php" ]; then
                echo -e "${YELLOW}[$i]${NC} $folder ${GREEN}*${NC}"
            else
                echo -e "${YELLOW}[$i]${NC} $folder"
            fi
            
            folders[$i]=$folder
            i=$((i+1))
        done
        
        if [ ${#folders[@]} -eq 0 ]; then
            echo "Aucun dossier trouvé"
            return 1
        fi
        
        # Demander le choix du dossier
        read -p "$(echo -e ${YELLOW}Entrez le numéro du dossier à déployer [1-$((i-1))]${NC}: )" folder_number
        
        if [ "$folder_number" -ge 1 ] && [ "$folder_number" -lt "$i" ]; then
            site_name=${folders[$folder_number]}
        else
            log_error "Numéro de dossier invalide"
            return 1
        fi
    else
        # Option 2: Spécifier manuellement le chemin
        read -p "$(echo -e ${YELLOW}Entrez le chemin complet du dossier du site${NC}: )" site_path
        
        # Vérifier si le chemin existe
        if [ ! -d "$site_path" ]; then
            log_error "Le dossier $site_path n'existe pas"
            return 1
        fi
        
        # Extraire le nom du dossier du chemin
        site_name=$(basename "$site_path")
    fi

    # Demander le nom de domaine
    echo -e "${YELLOW}Entrez le nom de domaine (ex: example.com) : ${NC}"
    read domain_name

    echo -e "\n${YELLOW}Déploiement du site $site_name vers $domain_name...${NC}"
    
    # Créer le répertoire sur le serveur
    sudo mkdir -p "/var/www/$site_name"
    
    # Copier les fichiers
    if [ "$selection_choice" = "1" ]; then
        # Si sélection parmi les dossiers listés
        sudo cp -r "$site_name"/* "/var/www/$site_name/"
    else
        # Si chemin spécifié manuellement
        sudo cp -r "$site_path"/* "/var/www/$site_name/"
    fi
    
    # Configurer les permissions
    sudo chown -R www-data:www-data "/var/www/$site_name"
    sudo chmod -R 755 "/var/www/$site_name"
    
    # Créer la configuration Apache
    sudo bash -c "cat > /etc/apache2/sites-available/$domain_name.conf << EOF
<VirtualHost *:80>
    ServerName $domain_name
    ServerAlias www.$domain_name
    DocumentRoot /var/www/$site_name
    ErrorLog \${APACHE_LOG_DIR}/${domain_name}_error.log
    CustomLog \${APACHE_LOG_DIR}/${domain_name}_access.log combined
    
    <Directory /var/www/$site_name>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF"

    # Activer le site
    sudo a2ensite "$domain_name.conf"
    
    # Redémarrer Apache
    sudo systemctl restart apache2
    
    echo -e "${GREEN}✓ Site déployé avec succès${NC}"
    echo -e "\n${YELLOW}Étapes suivantes :${NC}"
    echo -e "1. Configurez votre DNS pour pointer vers $(hostname -I | cut -d' ' -f1)"
    echo -e "2. Ajoutez ces enregistrements DNS :"
    echo -e "   Type A : $domain_name → $(hostname -I | cut -d' ' -f1)"
    echo -e "   Type A : www.$domain_name → $(hostname -I | cut -d' ' -f1)"
    echo -e "3. Pour HTTPS, exécutez : sudo certbot --apache -d $domain_name -d www.$domain_name"
}

# Nouvelle fonction pour vérifier les DNS
check_dns() {
    local domain=$1
    echo -e "\n${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}         ${GREEN}Vérification DNS${NC}                  ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"
    
    local server_ip=$(hostname -I | cut -d' ' -f1)
    
    echo -e "${YELLOW}Configuration DNS requise sur IONOS :${NC}"
    echo -e "1. Type A : $domain → $server_ip"
    echo -e "2. Type A : www.$domain → $server_ip"
    echo -e "\n${YELLOW}Vérification des enregistrements...${NC}\n"
    
    # Vérifier l'enregistrement principal
    echo -ne "1. Vérification de $domain : "
    if host $domain > /dev/null 2>&1; then
        local domain_ip=$(host $domain | awk '/has address/ {print $4}')
        if [ "$domain_ip" = "$server_ip" ]; then
            echo -e "${GREEN}✓ OK${NC}"
        else
            echo -e "${RED}✗ IP incorrecte ($domain_ip)${NC}"
        fi
    else
        echo -e "${RED}✗ Non configuré${NC}"
    fi
    
    # Vérifier le www
    echo -ne "2. Vérification de www.$domain : "
    if host www.$domain > /dev/null 2>&1; then
        local www_ip=$(host www.$domain | awk '/has address/ {print $4}')
        if [ "$www_ip" = "$server_ip" ]; then
            echo -e "${GREEN}✓ OK${NC}"
        else
            echo -e "${RED}✗ IP incorrecte ($www_ip)${NC}"
        fi
    else
        echo -e "${RED}✗ Non configuré${NC}"
    fi

    # Afficher les instructions si nécessaire
    if ! host $domain > /dev/null 2>&1 || ! host www.$domain > /dev/null 2>&1; then
        echo -e "\n${YELLOW}Instructions :${NC}"
        echo "1. Connectez-vous à IONOS"
        echo "2. Allez dans la section DNS"
        echo "3. Ajoutez les enregistrements manquants"
        echo "4. Attendez 5-15 minutes pour la propagation"
    fi
}

# Modification de la fonction configure_https
configure_https() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}      ${GREEN}Configuration HTTPS (SSL)${NC}            ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

    # Vérifier si certbot est installé
    if ! command -v certbot &> /dev/null; then
        echo -e "${YELLOW}Installation de Certbot...${NC}"
        sudo apt update
        sudo apt install -y certbot python3-certbot-apache
    fi

    # Lister les sites disponibles
    echo -e "${YELLOW}Sites disponibles :${NC}"
    ls /etc/apache2/sites-available/ | grep -v "^default" | grep -v "^000-default"
    echo ""

    # Demander le domaine
    read -p $'\e[1;33mEntrez le nom du domaine (ex: example.com) : \e[0m' domain_name

    # Vérifier les DNS avant de continuer
    check_dns "$domain_name"

    echo -e "\n${YELLOW}Vérifiez que les DNS sont correctement configurés sur IONOS :${NC}"
    echo -e "1. Type A : $domain_name → $(hostname -I | cut -d' ' -f1)"
    echo -e "2. Type A : www.$domain_name → $(hostname -I | cut -d' ' -f1)"
    
    read -p $'\e[1;33m\nLes DNS sont-ils configurés ? (o/n) : \e[0m' dns_ready
    
    if [ "$dns_ready" = "o" ]; then
        echo -e "\n${YELLOW}Configuration de HTTPS pour $domain_name...${NC}"
        if sudo certbot --apache -d "$domain_name" -d "www.$domain_name"; then
            echo -e "${GREEN}✓ HTTPS configuré avec succès pour $domain_name${NC}"
            echo -e "${GREEN}✓ Le certificat sera automatiquement renouvelé${NC}"
        else
            log_error "Échec de la configuration HTTPS"
            echo -e "${YELLOW}Suggestions :${NC}"
            echo "1. Vérifiez que les DNS sont bien propagés (peut prendre jusqu'à 48h)"
            echo "2. Vérifiez que le port 443 est ouvert (sudo ufw status)"
            echo "3. Vérifiez les logs : /var/log/letsencrypt/letsencrypt.log"
        fi
    else
        echo -e "\n${YELLOW}Configurez d'abord les DNS sur IONOS puis réessayez${NC}"
    fi
}

# Fonction pour vérifier et réparer la configuration
check_repair_site() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}    ${GREEN}Vérification/Réparation des Sites${NC}      ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

    # Lister les sites dans /var/www/
    echo -e "${YELLOW}Sites dans /var/www/ :${NC}"
    ls -l /var/www/
    echo ""

    # Lister les configurations Apache
    echo -e "${YELLOW}Configurations Apache disponibles :${NC}"
    ls -l /etc/apache2/sites-available/
    echo ""

    # Lister les sites activés
    echo -e "${YELLOW}Sites activés :${NC}"
    ls -l /etc/apache2/sites-enabled/
    echo ""

    # Demander le domaine à vérifier/réparer
    read -p $'\e[1;33mEntrez le nom du domaine à vérifier/réparer (ex: wagon.skandy.online) : \e[0m' domain_name

    echo -e "\n${YELLOW}Vérification de la configuration pour $domain_name...${NC}"

    # Vérifier le dossier dans /var/www/
    site_name=$(echo $domain_name | cut -d. -f1)
    if [ ! -d "/var/www/$site_name" ]; then
        echo -e "${RED}✗ Dossier /var/www/$site_name manquant${NC}"
        read -p $'\e[1;33mVoulez-vous recréer le dossier ? (o/n) : \e[0m' create_dir
        if [ "$create_dir" = "o" ]; then
            sudo mkdir -p "/var/www/$site_name"
            sudo chown -R www-data:www-data "/var/www/$site_name"
            sudo chmod -R 755 "/var/www/$site_name"
            echo -e "${GREEN}✓ Dossier créé${NC}"
        fi
    else
        echo -e "${GREEN}✓ Dossier /var/www/$site_name existe${NC}"
    fi

    # Vérifier la configuration Apache
    if [ ! -f "/etc/apache2/sites-available/$domain_name.conf" ]; then
        echo -e "${RED}✗ Configuration Apache manquante${NC}"
        read -p $'\e[1;33mVoulez-vous recréer la configuration ? (o/n) : \e[0m' create_conf
        if [ "$create_conf" = "o" ]; then
            sudo bash -c "cat > /etc/apache2/sites-available/$domain_name.conf << EOF
<VirtualHost *:80>
    ServerName $domain_name
    ServerAlias www.$domain_name
    DocumentRoot /var/www/$site_name
    DirectoryIndex index.html wagons.html
    ErrorLog \${APACHE_LOG_DIR}/${domain_name}_error.log
    CustomLog \${APACHE_LOG_DIR}/${domain_name}_access.log combined
    
    <Directory /var/www/$site_name>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF"
            echo -e "${GREEN}✓ Configuration Apache créée${NC}"
        fi
    else
        echo -e "${GREEN}✓ Configuration Apache existe${NC}"
    fi

    # Vérifier si le site est activé
    if [ ! -f "/etc/apache2/sites-enabled/$domain_name.conf" ]; then
        echo -e "${RED}✗ Site non activé${NC}"
        read -p $'\e[1;33mVoulez-vous activer le site ? (o/n) : \e[0m' enable_site
        if [ "$enable_site" = "o" ]; then
            sudo a2ensite "$domain_name.conf"
            echo -e "${GREEN}✓ Site activé${NC}"
        fi
    else
        echo -e "${GREEN}✓ Site déjà activé${NC}"
    fi

    # Vérifier la syntaxe de la configuration
    echo -e "\n${YELLOW}Vérification de la syntaxe Apache...${NC}"
    if sudo apache2ctl configtest; then
        echo -e "${GREEN}✓ Syntaxe correcte${NC}"
    else
        echo -e "${RED}✗ Erreur de syntaxe détectée${NC}"
    fi

    # Redémarrer Apache si des modifications ont été faites
    read -p $'\e[1;33mVoulez-vous redémarrer Apache ? (o/n) : \e[0m' restart_apache
    if [ "$restart_apache" = "o" ]; then
        sudo systemctl restart apache2
        echo -e "${GREEN}✓ Apache redémarré${NC}"
    fi
}

# Fonction pour diagnostiquer et réparer SSL
diagnose_ssl() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}      ${GREEN}Diagnostic SSL/HTTPS${NC}                 ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

    # Vérifier si certbot est installé
    if ! command -v certbot &> /dev/null; then
        echo -e "${YELLOW}Installation de Certbot...${NC}"
        sudo apt update
        sudo apt install -y certbot python3-certbot-apache
    fi  

    # Lister les certificats existants
    echo -e "${YELLOW}Certificats SSL existants :${NC}"
    sudo certbot certificates
    echo ""

    # Demander le domaine à diagnostiquer
    read -p $'\e[1;33mEntrez le nom du domaine à diagnostiquer (ex: poney.skandy.online) : \e[0m' domain_name

    echo -e "\n${YELLOW}Diagnostic SSL pour $domain_name...${NC}"

    # 1. Vérifier le module SSL
    echo -e "\n${YELLOW}1. Vérification du module SSL...${NC}"
    if apache2ctl -M | grep ssl_module > /dev/null; then
        echo -e "${GREEN}✓ Module SSL activé${NC}"
    else
        echo -e "${RED}✗ Module SSL non activé${NC}"
        read -p $'\e[1;33mVoulez-vous activer le module SSL ? (o/n) : \e[0m' enable_ssl
        if [ "$enable_ssl" = "o" ]; then
            sudo a2enmod ssl
            sudo systemctl restart apache2
            echo -e "${GREEN}✓ Module SSL activé${NC}"
        fi
    fi

    # 2. Vérifier le port 443
    echo -e "\n${YELLOW}2. Vérification du port 443...${NC}"
    if sudo netstat -tuln | grep ":443 " > /dev/null; then
        echo -e "${GREEN}✓ Port 443 ouvert${NC}"
    else
        echo -e "${RED}✗ Port 443 non ouvert${NC}"
        read -p $'\e[1;33mVoulez-vous ouvrir le port 443 ? (o/n) : \e[0m' open_port
        if [ "$open_port" = "o" ]; then
            sudo ufw allow 443/tcp
            echo -e "${GREEN}✓ Port 443 ouvert${NC}"
        fi
    fi

    # 3. Vérifier le certificat
    echo -e "\n${YELLOW}3. Vérification du certificat...${NC}"
    if sudo certbot certificates | grep "$domain_name" > /dev/null; then
        echo -e "${GREEN}✓ Certificat trouvé${NC}"
        read -p $'\e[1;33mVoulez-vous renouveler le certificat ? (o/n) : \e[0m' renew_cert
        if [ "$renew_cert" = "o" ]; then
            sudo certbot --apache -d "$domain_name" -d "www.$domain_name" --force-renewal
        fi
    else
        echo -e "${RED}✗ Certificat non trouvé${NC}"
        read -p $'\e[1;33mVoulez-vous créer un nouveau certificat ? (o/n) : \e[0m' new_cert
        if [ "$new_cert" = "o" ]; then
            sudo certbot --apache -d "$domain_name" -d "www.$domain_name"
        fi
    fi

    # 4. Vérifier la configuration SSL Apache
    echo -e "\n${YELLOW}4. Vérification de la configuration Apache SSL...${NC}"
    if [ -f "/etc/apache2/sites-available/$domain_name-le-ssl.conf" ]; then
        echo -e "${GREEN}✓ Configuration SSL trouvée${NC}"
        echo -e "\n${YELLOW}Contenu de la configuration SSL :${NC}"
        sudo cat "/etc/apache2/sites-available/$domain_name-le-ssl.conf"
    else
        echo -e "${RED}✗ Configuration SSL non trouvée${NC}"
    fi

    # 5. Test de la configuration Apache
    echo -e "\n${YELLOW}5. Test de la configuration Apache...${NC}"
    if sudo apache2ctl configtest; then
        echo -e "${GREEN}✓ Configuration Apache valide${NC}"
    else
        echo -e "${RED}✗ Erreur dans la configuration Apache${NC}"
    fi

    # Proposer un redémarrage d'Apache
    read -p $'\e[1;33mVoulez-vous redémarrer Apache ? (o/n) : \e[0m' restart_apache
    if [ "$restart_apache" = "o" ]; then
        sudo systemctl restart apache2
        echo -e "${GREEN}✓ Apache redémarré${NC}"
    fi
}

# Menu de gestion des sites modifié
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
        echo -e "${BLUE}║${NC}  ${RED}[0]${NC} Retour                              ${BLUE}║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
        
        read -p "$(echo -e ${YELLOW}Entrez votre choix [0-7]${NC}: )" site_choice

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

# Fonction pour afficher le menu et gérer la sélection
show_menu() {
    while true; do
        clear
        show_bash_version  # Ajout de l'affichage de la version
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
            2) apache_menu ;;  # Appel du sous-menu Apache
            3) manage_sites ;;  # Remplacer l'ancien "Option 3 sélectionnée"
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

# Menu principal d'Apache
apache_menu() {
    while true; do
        clear
        show_bash_version  # Ajout de l'affichage de la version
        echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║${NC}        ${GREEN}Gestion d'Apache${NC}                   ${BLUE}║${NC}"
        echo -e "${BLUE}╠════════════════════════════════════════════╣${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[1]${NC} Installer Apache                     ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[2]${NC} Démarrer Apache                     ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[3]${NC} Arrêter Apache                      ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[4]${NC} Redémarrer Apache                   ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[5]${NC} Statut Apache                       ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}[6]${NC} Configuration Apache                 ${BLUE}║${NC}"
        echo -e "${BLUE}║${NC}  ${RED}[0]${NC} Retour au menu principal            ${BLUE}║${NC}"
        echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
        
        read -p "$(echo -e ${YELLOW}Entrez votre choix [0-6]${NC}: )" apache_choice

        case $apache_choice in
            1) install_apache ;;
            2) start_apache ;;
            3) stop_apache ;;
            4) restart_apache ;;
            5) status_apache ;;
            6) configure_apache ;;
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

# Lancement du menu
show_menu
