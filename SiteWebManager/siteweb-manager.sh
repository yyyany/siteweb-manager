#!/bin/bash
# Version du script
VERSION="1.21"

# Détection du chemin absolu du script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$SCRIPT_DIR"

# Affichage du chemin pour vérification
echo "Chemin d'exécution: $BASE_DIR"

# Chargement de la configuration
if [ -f "$BASE_DIR/config/config.sh" ]; then
    source "$BASE_DIR/config/config.sh"
else
    echo "ERREUR: Fichier de configuration non trouvé: $BASE_DIR/config/config.sh"
    exit 1
fi

# Chargement des modules
for module in "$BASE_DIR/lib/utils.sh" "$BASE_DIR/lib/system.sh" "$BASE_DIR/lib/apache.sh" "$BASE_DIR/lib/sites.sh" "$BASE_DIR/lib/ssl.sh"; do
    if [ -f "$module" ]; then
        source "$module"
    else
        echo "ERREUR: Module non trouvé: $module"
        exit 1
    fi
done

# Chargement de l'interface utilisateur
if [ -f "$BASE_DIR/ui/menus.sh" ]; then
    source "$BASE_DIR/ui/menus.sh"
else
    echo "ERREUR: Interface utilisateur non trouvée: $BASE_DIR/ui/menus.sh"
    exit 1
fi

# Lancement du menu principal
show_menu