#!/bin/bash

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

    # Désactiver le site par défaut pour éviter les conflits
    echo -e "${YELLOW}Désactivation du site par défaut...${NC}"
    sudo a2dissite 000-default.conf
    
    # Activer le site
    echo -e "${YELLOW}Activation du site $domain_name...${NC}"
    sudo a2ensite "$domain_name.conf"
    
    # Redémarrer Apache
    sudo systemctl restart apache2
    
    # Vérifier la configuration des hôtes virtuels
    echo -e "\n${YELLOW}Vérification de la configuration des hôtes virtuels :${NC}"
    apache2ctl -S
    
    echo -e "${GREEN}✓ Site déployé avec succès${NC}"
    echo -e "\n${YELLOW}Étapes suivantes :${NC}"
    echo -e "1. Configurez votre DNS pour pointer vers $(hostname -I | cut -d' ' -f1)"
    echo -e "2. Ajoutez ces enregistrements DNS :"
    echo -e "   Type A : $domain_name → $(hostname -I | cut -d' ' -f1)"
    echo -e "   Type A : www.$domain_name → $(hostname -I | cut -d' ' -f1)"
    echo -e "3. Pour HTTPS, exécutez : sudo certbot --apache -d $domain_name -d www.$domain_name"
}

# Fonction pour vérifier les DNS
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
            # Désactiver le site par défaut pour éviter les conflits
            echo -e "${YELLOW}Désactivation du site par défaut...${NC}"
            sudo a2dissite 000-default.conf
            
            # Activer le site
            sudo a2ensite "$domain_name.conf"
            echo -e "${GREEN}✓ Site activé${NC}"
            
            # Vérifier la configuration des hôtes virtuels
            echo -e "\n${YELLOW}Vérification de la configuration des hôtes virtuels :${NC}"
            apache2ctl -S
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