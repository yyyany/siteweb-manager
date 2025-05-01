#!/bin/bash
# Version du script
VERSION="1.21"

# Détection du chemin absolu du script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Support pour le chemin alternatif si le script est appelé depuis un autre emplacement
if [[ "$SCRIPT_DIR" == */SiteWebManager ]]; then
    BASE_DIR="$SCRIPT_DIR"
elif [[ "$SCRIPT_DIR" == */siteweb-manager/SiteWebManager ]]; then
    BASE_DIR="$SCRIPT_DIR"
else
    # Chercher le bon répertoire
    if [ -d "/home/ubuntu/siteweb-manager/SiteWebManager" ]; then
        BASE_DIR="/home/ubuntu/siteweb-manager/SiteWebManager"
    elif [ -d "$SCRIPT_DIR/SiteWebManager" ]; then
        BASE_DIR="$SCRIPT_DIR/SiteWebManager"
    else
        echo "ERREUR: Impossible de déterminer le chemin de base. Chemin actuel: $SCRIPT_DIR"
        exit 1
    fi
fi

echo "Chemin d'exécution: $SCRIPT_DIR"
echo "Chemin de base: $BASE_DIR"

# Définition explicite des chemins vers les modules
CONFIG_FILE="$BASE_DIR/config/config.sh"
UTILS_FILE="$BASE_DIR/lib/utils.sh"
SYSTEM_FILE="$BASE_DIR/lib/system.sh"
APACHE_FILE="$BASE_DIR/lib/apache.sh"
SITES_FILE="$BASE_DIR/lib/sites.sh"
SSL_FILE="$BASE_DIR/lib/ssl.sh"
MENUS_FILE="$BASE_DIR/ui/menus.sh"

# Exportation des chemins pour les autres scripts
export BASE_DIR CONFIG_FILE UTILS_FILE SYSTEM_FILE APACHE_FILE SITES_FILE SSL_FILE MENUS_FILE

# Chargement de la configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo "Configuration chargée: $CONFIG_FILE"
else
    echo "ERREUR: Fichier de configuration non trouvé: $CONFIG_FILE"
    exit 1
fi

# Chargement des modules un par un avec vérification
echo "Chargement des modules..."

if [ -f "$UTILS_FILE" ]; then
    source "$UTILS_FILE"
    echo "✓ Module utils chargé"
else
    echo "ERREUR: Module utils non trouvé: $UTILS_FILE"
    exit 1
fi

if [ -f "$SYSTEM_FILE" ]; then
    source "$SYSTEM_FILE"
    echo "✓ Module system chargé"
else
    echo "ERREUR: Module system non trouvé: $SYSTEM_FILE"
    exit 1
fi

if [ -f "$APACHE_FILE" ]; then
    source "$APACHE_FILE"
    echo "✓ Module apache chargé"
else
    echo "ERREUR: Module apache non trouvé: $APACHE_FILE"
    exit 1
fi

if [ -f "$SITES_FILE" ]; then
    source "$SITES_FILE"
    echo "✓ Module sites chargé"
else
    echo "ERREUR: Module sites non trouvé: $SITES_FILE"
    exit 1
fi

if [ -f "$SSL_FILE" ]; then
    source "$SSL_FILE"
    echo "✓ Module SSL chargé"
    # Vérifier explicitement la fonction configure_https
    if ! declare -f "configure_https" > /dev/null; then
        echo "ERREUR: Fonction 'configure_https' non définie dans $SSL_FILE"
        echo "Premières lignes du fichier SSL:"
        head -n 20 "$SSL_FILE"
        exit 1
    fi
    echo "✓ Fonction configure_https vérifiée"
else
    echo "ERREUR: Module SSL non trouvé: $SSL_FILE"
    exit 1
fi

# Chargement de l'interface utilisateur
if [ -f "$MENUS_FILE" ]; then
    source "$MENUS_FILE"
    echo "✓ Interface utilisateur chargée"
    
    # Vérifier la fonction principale de menu
    if ! declare -f "show_menu" > /dev/null; then
        echo "ERREUR: Fonction 'show_menu' non définie dans $MENUS_FILE"
        exit 1
    fi
else
    echo "ERREUR: Interface utilisateur non trouvée: $MENUS_FILE"
    exit 1
fi

echo "Toutes les vérifications réussies. Démarrage du script..."
echo "-------------------------------------------------------"

# Lancement du menu principal
show_menu