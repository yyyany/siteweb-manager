#!/bin/bash
# Définition des couleurs pour l'interface utilisateur

# Couleurs de base
BLACK="\e[30m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
WHITE="\e[37m"
GRAY="\e[90m"

# Couleurs en gras
BOLD_BLACK="\e[1;30m"
BOLD_RED="\e[1;31m"
BOLD_GREEN="\e[1;32m"
BOLD_YELLOW="\e[1;33m"
BOLD_BLUE="\e[1;34m"
BOLD_MAGENTA="\e[1;35m"
BOLD_CYAN="\e[1;36m"
BOLD_WHITE="\e[1;37m"

# Couleurs de fond
BG_BLACK="\e[40m"
BG_RED="\e[41m"
BG_GREEN="\e[42m"
BG_YELLOW="\e[43m"
BG_BLUE="\e[44m"
BG_MAGENTA="\e[45m"
BG_CYAN="\e[46m"
BG_WHITE="\e[47m"

# Réinitialisation
NC="\e[0m"  # No Color

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