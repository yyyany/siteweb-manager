#!/bin/bash
# Fonctions d'affichage pour l'interface utilisateur

# Afficher un en-tête
show_header() {
    clear
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}        SiteWeb Manager v$VERSION${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo
}

# Afficher un message de succès
show_success() {
    local message=$1
    echo -e "${GREEN}[✓] $message${NC}"
}

# Afficher un message d'erreur
show_error() {
    local message=$1
    echo -e "${RED}[✗] $message${NC}"
}

# Afficher un message d'avertissement
show_warning() {
    local message=$1
    echo -e "${YELLOW}[!] $message${NC}"
}

# Afficher un message d'information
show_info() {
    local message=$1
    echo -e "${CYAN}[i] $message${NC}"
}

# Afficher une barre de progression
show_progress() {
    local current=$1
    local total=$2
    local width=50
    
    # Calcul du pourcentage
    local percent=$((current * 100 / total))
    local filled=$((width * percent / 100))
    local empty=$((width - filled))
    
    # Construction de la barre
    local bar="["
    for ((i=0; i<filled; i++)); do
        bar+="="
    done
    for ((i=0; i<empty; i++)); do
        bar+=" "
    done
    bar+="] $percent%"
    
    # Affichage
    echo -ne "\r${BLUE}$bar${NC}"
}

# Afficher un menu
show_menu() {
    local title=$1
    local options=("${@:2}")
    
    echo -e "${BLUE}=== $title ===${NC}"
    echo
    
    for ((i=0; i<${#options[@]}; i++)); do
        echo -e "${GREEN}$((i+1)).${NC} ${options[$i]}"
    done
    
    echo
    echo -e "${GREEN}0.${NC} Retour"
    echo
}

# Afficher un tableau
show_table() {
    local headers=("${@:1}")
    local data=("${@:2}")
    local col_width=20
    
    # Affichage des en-têtes
    for header in "${headers[@]}"; do
        printf "%-${col_width}s" "$header"
    done
    echo
    
    # Ligne de séparation
    for ((i=0; i<${#headers[@]}; i++)); do
        printf "%-${col_width}s" "-------------------"
    done
    echo
    
    # Affichage des données
    for row in "${data[@]}"; do
        IFS='|' read -ra fields <<< "$row"
        for field in "${fields[@]}"; do
            printf "%-${col_width}s" "$field"
        done
        echo
    done
}

# Afficher une confirmation
show_confirm() {
    local message=$1
    local default=$2
    
    if [[ -z "$default" ]]; then
        default="n"
    fi
    
    while true; do
        if [[ "$default" == "y" ]]; then
            read -p "$message (Y/n) " response
        else
            read -p "$message (y/N) " response
        fi
        
        case "$response" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            "" ) [[ "$default" == "y" ]] && return 0 || return 1;;
            * ) echo "Veuillez répondre par oui (y) ou non (n).";;
        esac
    done
}

# Afficher un message de chargement
show_loading() {
    local message=$1
    local delay=0.1
    local chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    
    echo -ne "${CYAN}$message ${chars[0]}${NC}"
    
    while true; do
        for char in "${chars[@]}"; do
            echo -ne "\r${CYAN}$message $char${NC}"
            sleep $delay
        done
    done
}

# Afficher un message de fin
show_footer() {
    echo
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}        Merci d'avoir utilisé SiteWeb Manager${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo
} 