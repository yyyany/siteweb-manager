#!/bin/bash

# Fonction pour les messages de log
log_message() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Fonction pour les messages d'erreur
log_error() {
    echo -e "${RED}[ERREUR] $1${NC}"
}

# Fonction pour afficher la version de bash
show_bash_version() {
    local bash_version=$(bash --version | head -n1)
    echo -e "${BLUE}Version du script : ${NC}v${VERSION}"
    echo -e "${BLUE}Version Bash : ${NC}$bash_version"
    echo -e "${BLUE}Date : ${NC}$(date '+%Y-%m-%d %H:%M:%S')\n"
} 