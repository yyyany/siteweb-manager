#!/bin/bash

echo "----- Diagnostic de chemins pour SiteWebManager -----"

# Obtenir le chemin absolu du script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Répertoire d'exécution: $SCRIPT_DIR"

# Vérifier la structure des dossiers
echo
echo "Vérification de la structure des dossiers:"
for dir in "config" "lib" "ui"; do
    if [ -d "$SCRIPT_DIR/$dir" ]; then
        echo "✓ Répertoire $dir trouvé: $SCRIPT_DIR/$dir"
        ls -la "$SCRIPT_DIR/$dir"
    else
        echo "✗ Répertoire $dir NON TROUVÉ: $SCRIPT_DIR/$dir"
    fi
    echo
done

# Vérifier les fichiers principaux
echo "Vérification des fichiers principaux:"
files=(
    "config/config.sh"
    "lib/utils.sh"
    "lib/system.sh"
    "lib/apache.sh"
    "lib/sites.sh"
    "lib/ssl.sh"
    "ui/menus.sh"
)

for file in "${files[@]}"; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        echo "✓ Fichier $file trouvé"
        grep -q "function" "$SCRIPT_DIR/$file" && echo "   (contient des définitions de fonctions)"
    else
        echo "✗ Fichier $file NON TROUVÉ"
    fi
done

# Vérifier si le fichier ssl.sh est lisible et contient la fonction configure_https
if [ -f "$SCRIPT_DIR/lib/ssl.sh" ]; then
    echo
    echo "Analyse du fichier ssl.sh:"
    
    if grep -q "configure_https()" "$SCRIPT_DIR/lib/ssl.sh"; then
        echo "✓ Fonction configure_https trouvée dans ssl.sh"
    else
        echo "✗ Fonction configure_https NON TROUVÉE dans ssl.sh"
        echo "Premières lignes du fichier ssl.sh:"
        head -n 20 "$SCRIPT_DIR/lib/ssl.sh"
    fi
    
    echo "Permissions du fichier ssl.sh:"
    ls -la "$SCRIPT_DIR/lib/ssl.sh"
fi

echo
echo "Vérification de la source du script principal:"
if [ -f "$SCRIPT_DIR/siteweb-manager.sh" ]; then
    echo "Contenu du script principal:"
    grep -n "source" "$SCRIPT_DIR/siteweb-manager.sh"
else
    echo "Script principal non trouvé!"
fi 