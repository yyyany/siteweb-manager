#!/bin/bash
# SiteWeb Manager - Script de gestion de serveur web
VERSION="2.1.1"

# Détection du chemin du script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$SCRIPT_DIR"

# Vérifier si le script est exécuté avec les privilèges root
if [[ $EUID -ne 0 ]]; then
   echo "Ce script doit être exécuté avec des privilèges root (sudo)" 
   exit 1
fi

# Chargement de la configuration
source "$BASE_DIR/config/config.sh"
source "$BASE_DIR/config/colors.sh"

# Chargement des modules (ordre optimisé selon les dépendances)
source "$BASE_DIR/lib/utils.sh"       # Utilitaires de base utilisés par tous les modules
source "$BASE_DIR/ui/display.sh"      # Fonctions d'affichage utilisées par tous les modules
source "$BASE_DIR/lib/system.sh"      # Fonctions système de base
source "$BASE_DIR/lib/apache.sh"      # Apache (requis pour sites et ssl)
source "$BASE_DIR/lib/sites.sh"       # Gestion des sites
source "$BASE_DIR/lib/ssl.sh"         # SSL (dépend d'Apache et sites)
source "$BASE_DIR/lib/php.sh"         # PHP (dépend d'Apache)
source "$BASE_DIR/lib/db.sh"          # Base de données

# Chargement de l'interface utilisateur
source "$BASE_DIR/ui/menus.sh"        # Menus (dépend de tous les modules)

# Fonction pour afficher la version
show_version() {
    echo -e "${BLUE}SiteWeb Manager${NC} - Version ${GREEN}$VERSION${NC}"
    echo -e "Date de build: $(date '+%Y-%m-%d')"
    echo ""
}

# Vérification des prérequis
check_prerequisites

# Gestion des arguments en ligne de commande
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
elif [[ "$1" == "--version" || "$1" == "-v" ]]; then
    show_version
    exit 0
fi

# Lancement du menu principal
show_main_menu 