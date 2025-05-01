#!/bin/bash

# Fonction pour configurer HTTPS
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

    # S'assurer que le site par défaut est désactivé
    echo -e "${YELLOW}Vérification du site par défaut...${NC}"
    if [ -f "/etc/apache2/sites-enabled/000-default.conf" ]; then
        echo -e "${YELLOW}Désactivation du site par défaut...${NC}"
        sudo a2dissite 000-default.conf
        sudo systemctl reload apache2
        echo -e "${GREEN}✓ Site par défaut désactivé${NC}"
    else
        echo -e "${GREEN}✓ Site par défaut déjà désactivé${NC}"
    fi

    # Lister les sites disponibles
    echo -e "${YELLOW}Sites disponibles :${NC}"
    ls /etc/apache2/sites-available/ | grep -v "^default" | grep -v "^000-default"
    echo ""

    # Demander le domaine
    read -p $'\e[1;33mEntrez le nom du domaine (ex: example.com) : \e[0m' domain_name

    # Vérifier les DNS avant de continuer
    check_dns "$domain_name"

    # Vérifier que le site est activé
    if [ ! -f "/etc/apache2/sites-enabled/$domain_name.conf" ]; then
        echo -e "${RED}✗ Le site $domain_name n'est pas activé${NC}"
        read -p $'\e[1;33mVoulez-vous l'activer ? (o/n) : \e[0m' activate_site
        if [ "$activate_site" = "o" ]; then
            sudo a2ensite "$domain_name.conf"
            sudo systemctl reload apache2
            echo -e "${GREEN}✓ Site activé${NC}"
        else
            echo -e "${YELLOW}Impossible de continuer sans activer le site${NC}"
            return 1
        fi
    fi

    echo -e "\n${YELLOW}Vérification de la configuration des hôtes virtuels :${NC}"
    apache2ctl -S

    echo -e "\n${YELLOW}Vérifiez que les DNS sont correctement configurés sur IONOS :${NC}"
    echo -e "1. Type A : $domain_name → $(hostname -I | cut -d' ' -f1)"
    echo -e "2. Type A : www.$domain_name → $(hostname -I | cut -d' ' -f1)"
    
    read -p $'\e[1;33m\nLes DNS sont-ils configurés ? (o/n) : \e[0m' dns_ready
    
    if [ "$dns_ready" = "o" ]; then
        echo -e "\n${YELLOW}Configuration de HTTPS pour $domain_name...${NC}"
        if sudo certbot --apache -d "$domain_name" -d "www.$domain_name"; then
            echo -e "${GREEN}✓ HTTPS configuré avec succès pour $domain_name${NC}"
            echo -e "${GREEN}✓ Le certificat sera automatiquement renouvelé${NC}"
            
            # Vérifier la configuration finale
            echo -e "\n${YELLOW}Configuration finale des hôtes virtuels :${NC}"
            apache2ctl -S
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

    # S'assurer que le site par défaut est désactivé
    echo -e "${YELLOW}Vérification du site par défaut...${NC}"
    if [ -f "/etc/apache2/sites-enabled/000-default.conf" ]; then
        echo -e "${RED}✗ Le site par défaut est activé (potentielle source de conflit)${NC}"
        read -p $'\e[1;33mVoulez-vous le désactiver ? (o/n) : \e[0m' disable_default
        if [ "$disable_default" = "o" ]; then
            sudo a2dissite 000-default.conf
            sudo systemctl reload apache2
            echo -e "${GREEN}✓ Site par défaut désactivé${NC}"
        fi
    else
        echo -e "${GREEN}✓ Site par défaut correctement désactivé${NC}"
    fi

    # Demander le domaine à diagnostiquer
    read -p $'\e[1;33mEntrez le nom du domaine à diagnostiquer (ex: poney.skandy.online) : \e[0m' domain_name

    echo -e "\n${YELLOW}Diagnostic SSL pour $domain_name...${NC}"

    # 0. Vérifier la configuration des hôtes virtuels
    echo -e "\n${YELLOW}0. Configuration actuelle des hôtes virtuels :${NC}"
    apache2ctl -S
    echo ""

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