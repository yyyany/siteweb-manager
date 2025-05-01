#!/bin/bash
# SiteWeb Manager - Script de gestion de serveur web
VERSION="2.0.0"

# Détection du chemin du script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$SCRIPT_DIR"

# Chargement de la configuration
source "$BASE_DIR/config/config.sh"
source "$BASE_DIR/config/colors.sh"

# Chargement des modules
source "$BASE_DIR/lib/utils.sh"
source "$BASE_DIR/lib/system.sh"
source "$BASE_DIR/lib/apache.sh"
source "$BASE_DIR/lib/sites.sh"
source "$BASE_DIR/lib/ssl.sh"
source "$BASE_DIR/lib/db.sh"
source "$BASE_DIR/lib/php.sh"

# Chargement de l'interface utilisateur
source "$BASE_DIR/ui/display.sh"
source "$BASE_DIR/ui/menus.sh"

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