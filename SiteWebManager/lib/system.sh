#!/bin/bash

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