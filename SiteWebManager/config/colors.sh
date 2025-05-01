#!/bin/bash
# Définition des couleurs pour l'affichage

# Couleurs de base
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
WHITE='\033[1;37m'
BLACK='\033[0;30m'
NC='\033[0m' # No Color

# Styles
BOLD='\033[1m'
UNDERLINE='\033[4m'
INVERTED='\033[7m'
BLINK='\033[5m'

# Fonctions d'utilisation des couleurs
print_green() {
    echo -e "${GREEN}$1${NC}"
}

print_blue() {
    echo -e "${BLUE}$1${NC}"
}

print_red() {
    echo -e "${RED}$1${NC}"
}

print_yellow() {
    echo -e "${YELLOW}$1${NC}"
}

# Fonction pour désactiver toutes les couleurs (mode non-interactif)
disable_colors() {
    GREEN=''
    BLUE=''
    RED=''
    YELLOW=''
    PURPLE=''
    CYAN=''
    GRAY=''
    WHITE=''
    BLACK=''
    NC=''
    BOLD=''
    UNDERLINE=''
    INVERTED=''
    BLINK=''
} 