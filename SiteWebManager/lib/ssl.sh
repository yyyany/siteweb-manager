#!/bin/bash
# Fonctions de gestion SSL

# Fonction pour installer Certbot
install_certbot() {
    log_info "Installation de Certbot..."
    
    # Mise à jour des paquets
    apt update
    
    # Installation de Certbot et du plugin Apache
    if apt install -y certbot python3-certbot-apache; then
        log_info "Certbot installé avec succès"
        return 0
    else
        log_error "Échec de l'installation de Certbot"
        return 1
    fi
}

# Fonction pour configurer HTTPS pour un site
configure_https() {
    local domain=$1
    
    # Validation du domaine
    if [[ -z "$domain" ]]; then
        log_error "Nom de domaine manquant"
        return 1
    fi
    
    # Vérification de l'installation de Certbot
    if ! command_exists certbot; then
        log_info "Certbot n'est pas installé, installation en cours..."
        install_certbot
    fi
    
    log_info "Configuration de HTTPS pour $domain..."
    
    # Vérification des DNS
    if ! check_dns "$domain"; then
        log_error "Les DNS ne sont pas correctement configurés pour $domain"
        return 1
    fi
    
    # Configuration avec Certbot
    if certbot --apache -d "$domain" -d "www.$domain"; then
        log_info "HTTPS configuré avec succès pour $domain"
        return 0
    else
        log_error "Échec de la configuration HTTPS pour $domain"
        return 1
    fi
}

# Fonction pour vérifier les DNS
check_dns() {
    local domain=$1
    
    # Validation du domaine
    if [[ -z "$domain" ]]; then
        log_error "Nom de domaine manquant"
        return 1
    fi
    
    log_info "Vérification des DNS pour $domain..."
    
    # Récupération de l'IP du serveur
    local server_ip=$(get_server_ip)
    
    # Vérification des enregistrements A
    local domain_ip=$(host "$domain" | grep "has address" | awk '{print $4}')
    local www_ip=$(host "www.$domain" | grep "has address" | awk '{print $4}')
    
    if [[ "$domain_ip" != "$server_ip" ]]; then
        log_error "L'enregistrement A pour $domain pointe vers $domain_ip au lieu de $server_ip"
        return 1
    fi
    
    if [[ "$www_ip" != "$server_ip" ]]; then
        log_error "L'enregistrement A pour www.$domain pointe vers $www_ip au lieu de $server_ip"
        return 1
    fi
    
    log_info "Les DNS sont correctement configurés pour $domain"
    return 0
}

# Fonction pour diagnostiquer les problèmes SSL
diagnose_ssl() {
    local domain=$1
    
    # Validation du domaine
    if [[ -z "$domain" ]]; then
        log_error "Nom de domaine manquant"
        return 1
    fi
    
    log_info "Diagnostic SSL pour $domain..."
    
    # Vérification du module SSL
    if ! apache2ctl -M | grep -q "ssl_module"; then
        log_error "Le module SSL n'est pas activé"
        return 1
    fi
    
    # Vérification du port 443
    if ! netstat -tuln | grep -q ":443"; then
        log_error "Le port 443 n'est pas en écoute"
        return 1
    fi
    
    # Vérification du certificat
    if ! certbot certificates | grep -q "$domain"; then
        log_error "Aucun certificat trouvé pour $domain"
        return 1
    fi
    
    # Vérification de la configuration SSL
    if ! grep -q "SSLCertificateFile" "/etc/apache2/sites-available/$domain-le-ssl.conf"; then
        log_error "La configuration SSL n'est pas correcte"
        return 1
    fi
    
    log_info "Diagnostic SSL terminé avec succès pour $domain"
    return 0
}

# Fonction pour renouveler les certificats
renew_certificates() {
    log_info "Renouvellement des certificats..."
    
    if certbot renew; then
        log_info "Certificats renouvelés avec succès"
        return 0
    else
        log_error "Échec du renouvellement des certificats"
        return 1
    fi
}

# Fonction pour vérifier l'expiration des certificats
check_certificate_expiration() {
    local domain=$1
    
    # Validation du domaine
    if [[ -z "$domain" ]]; then
        log_error "Nom de domaine manquant"
        return 1
    fi
    
    log_info "Vérification de l'expiration du certificat pour $domain..."
    
    # Récupération de la date d'expiration
    local expiration_date=$(certbot certificates | grep -A 2 "$domain" | grep "Expiry Date" | awk '{print $3, $4, $5}')
    
    if [[ -z "$expiration_date" ]]; then
        log_error "Aucun certificat trouvé pour $domain"
        return 1
    fi
    
    # Conversion en timestamp
    local expiration_timestamp=$(date -d "$expiration_date" +%s)
    local current_timestamp=$(date +%s)
    local days_remaining=$(( (expiration_timestamp - current_timestamp) / 86400 ))
    
    if [[ $days_remaining -le 0 ]]; then
        log_error "Le certificat pour $domain a expiré"
        return 1
    elif [[ $days_remaining -le 30 ]]; then
        log_warning "Le certificat pour $domain expire dans $days_remaining jours"
    else
        log_info "Le certificat pour $domain expire dans $days_remaining jours"
    fi
    
    return 0
} 