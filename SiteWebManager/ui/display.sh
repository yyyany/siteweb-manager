#!/bin/bash
# Fonctions d'affichage pour l'interface utilisateur

# Fonction pour effacer l'écran
clear_screen() {
    clear
}

# Fonction pour afficher l'en-tête de l'application
show_header() {
    local title="$1"
    local width=50
    
    clear_screen
    
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${GREEN}SiteWeb Manager v$VERSION${NC}                 ${BLUE}║${NC}"
    
    if [[ -n "$title" ]]; then
        echo -e "${BLUE}╠════════════════════════════════════════════╣${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}$title${NC}"
        # Compléter avec des espaces pour atteindre la largeur désirée
        local padding=$((width - ${#title} - 4))
        for ((i=0; i<padding; i++)); do
            echo -n " "
        done
        echo -e "${BLUE}║${NC}"
    fi
    
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
}

# Fonction pour afficher un message d'information
show_info() {
    local message="$1"
    echo -e "${CYAN}ℹ️ ${NC}${message}"
}

# Fonction pour afficher un message de succès
show_success() {
    local message="$1"
    echo -e "${GREEN}✓ ${NC}${message}"
}

# Fonction pour afficher un message d'avertissement
show_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠️ ${NC}${message}"
}

# Fonction pour afficher un message d'erreur
show_error() {
    local message="$1"
    echo -e "${RED}✗ ${NC}${message}"
}

# Fonction pour afficher le statut d'une commande
show_status() {
    local status=$1
    local success_msg=${2:-"Succès"}
    local error_msg=${3:-"Échec"}
    
    if [ $status -eq 0 ]; then
        show_success "$success_msg"
    else
        show_error "$error_msg"
    fi
}

# Fonction pour afficher une ligne de séparation
show_separator() {
    local char=${1:-"-"}
    local width=${2:-50}
    
    local line=""
    for ((i=0; i<width; i++)); do
        line+="$char"
    done
    
    echo -e "${BLUE}$line${NC}"
}

# Fonction pour afficher un menu
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    
    show_header "$title"
    
    local i=1
    for option in "${options[@]}"; do
        if [ "$option" = "separator" ]; then
            show_separator
        elif [ "$option" = "back" ]; then
            echo -e "  ${RED}[0]${NC} Retour"
        elif [ "$option" = "quit" ]; then
            echo -e "  ${RED}[0]${NC} Quitter"
        else
            echo -e "  ${YELLOW}[$i]${NC} $option"
            ((i++))
        fi
    done
    
    echo ""
}

# Fonction pour demander un choix à l'utilisateur
get_user_choice() {
    local prompt=${1:-"Entrez votre choix"}
    local max=${2:-0}
    local default=${3:-""}
    
    local choice
    
    while true; do
        read -p "$(echo -e ${YELLOW}$prompt${NC}${default:+ [$default]}${NC}: )" choice
        
        # Utiliser la valeur par défaut si l'entrée est vide
        choice=${choice:-$default}
        
        # Vérifier si le choix est un nombre
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            # Vérifier si le choix est dans la plage valide
            if [ $max -eq 0 ] || [ $choice -le $max ]; then
                break
            fi
        fi
        
        show_error "Choix invalide. Veuillez réessayer."
    done
    
    echo "$choice"
}

# Fonction pour demander une entrée à l'utilisateur
get_user_input() {
    local prompt="$1"
    local default="$2"
    local required=${3:-false}
    local hide_input=${4:-false}
    
    local input
    local arg=""
    
    # Ajouter la valeur par défaut à l'invite si elle existe
    if [[ -n "$default" ]]; then
        prompt="$prompt [$default]"
    fi
    
    while true; do
        if [[ "$hide_input" == true ]]; then
            read -s -p "$(echo -e ${YELLOW}$prompt${NC}: )" input
            echo ""  # Pour ajouter une nouvelle ligne après l'entrée masquée
        else
            read -p "$(echo -e ${YELLOW}$prompt${NC}: )" input
        fi
        
        # Utiliser la valeur par défaut si l'entrée est vide
        input=${input:-$default}
        
        # Vérifier si l'entrée est requise et non vide
        if [[ "$required" == true && -z "$input" ]]; then
            show_error "Une valeur est requise. Veuillez réessayer."
        else
            break
        fi
    done
    
    echo "$input"
}

# Fonction pour afficher un tableau
show_table() {
    local header=("$1")
    shift
    local data=("$@")
    local width=50
    local sep="|"
    
    # Déterminer la largeur des colonnes
    local columns=$(echo "$header" | tr "$sep" ' ' | wc -w)
    local col_width=$((width / columns))
    
    # Fonction pour formater une ligne de tableau
    format_line() {
        local line="$1"
        local cols=$(echo "$line" | tr "$sep" '\n')
        local formatted=""
        local i=1
        
        for col in $cols; do
            formatted+="| ${col:0:$((col_width-3))} "
            ((i++))
        done
        
        echo "$formatted|"
    }
    
    # Afficher l'en-tête
    show_separator "="
    format_line "$header"
    show_separator "-"
    
    # Afficher les données
    for row in "${data[@]}"; do
        format_line "$row"
    done
    
    show_separator "="
}

# Fonction pour afficher une boîte de texte
show_text_box() {
    local text="$1"
    local width=${2:-50}
    
    show_separator "═" $width
    
    # Découper le texte en lignes
    local lines=$(echo -e "$text" | fold -s -w $((width-4)))
    
    # Afficher chaque ligne dans la boîte
    while IFS= read -r line; do
        echo -e "│ ${line}$(printf ' %.0s' $(seq 1 $((width-${#line}-3))))│"
    done <<< "$lines"
    
    show_separator "═" $width
}

# Fonction pour afficher une barre de progression
show_progress_bar() {
    local current=$1
    local total=$2
    local width=${3:-40}
    
    show_progress $current $total $width
}

# Fonction pour afficher un spinner pendant l'exécution d'une commande
show_spinner() {
    local message="$1"
    local pid=$2
    local delay=0.1
    local spinstr='|/-\'
    
    while [ "$(ps a | awk '{print $1}' | grep -w $pid)" ]; do
        local temp=${spinstr#?}
        printf "\r[%c] %s" "$spinstr" "$message"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    
    printf "\r%*s\r" $((${#message} + 4)) ""
}

# Fonction pour afficher les informations système
show_system_info() {
    show_header "Informations Système"
    
    echo -e "${YELLOW}Système d'exploitation:${NC} $(lsb_release -ds 2>/dev/null || cat /etc/*release | grep -i pretty_name | cut -d= -f2 | tr -d '\"')"
    echo -e "${YELLOW}Version du noyau:${NC} $(uname -r)"
    echo -e "${YELLOW}Adresse IP:${NC} $(get_server_ip)"
    echo -e "${YELLOW}Nom d'hôte:${NC} $(hostname)"
    echo -e "${YELLOW}Utilisateur:${NC} $(whoami)"
    echo -e "${YELLOW}Date/heure:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
    
    echo ""
    
    # Afficher l'utilisation du processeur
    echo -e "${YELLOW}Utilisation CPU:${NC}"
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}'
    
    # Afficher l'utilisation de la mémoire
    echo -e "${YELLOW}Utilisation mémoire:${NC}"
    free -h | grep Mem | awk '{print $3" / "$2" ("$3/$2*100"%)"}'
    
    # Afficher l'utilisation du disque
    echo -e "${YELLOW}Utilisation disque:${NC}"
    df -h / | tail -n 1 | awk '{print $3" / "$2" ("$5")"}'
    
    echo ""
}

# Fonction pour attendre l'action de l'utilisateur
pause() {
    local message=${1:-"Appuyez sur Entrée pour continuer..."}
    read -p "$(echo -e ${YELLOW}$message${NC})" 
}

# Fonction pour afficher la date et l'heure actuelles
show_datetime() {
    echo -e "${GRAY}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
} 