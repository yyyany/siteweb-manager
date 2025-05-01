#!/bin/bash
# Version du script
VERSION="1.21"

# Détection du chemin du script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$SCRIPT_DIR"

# Chargement de la configuration
source "$BASE_DIR/config/config.sh"

# Chargement des modules
source "$BASE_DIR/lib/utils.sh"
source "$BASE_DIR/lib/system.sh"
source "$BASE_DIR/lib/apache.sh"
source "$BASE_DIR/lib/sites.sh"
source "$BASE_DIR/lib/ssl.sh"

# Chargement de l'interface utilisateur
source "$BASE_DIR/ui/menus.sh"

# Lancement du menu principal
show_menu 