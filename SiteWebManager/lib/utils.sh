#!/bin/bash
# Fonctions utilitaires partagées

# Fonction de journalisation améliorée
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    
    # Sélection de la couleur selon le niveau
    local color=""
    case "$level" in
        "DEBUG") color="${GRAY}" ;;
        "INFO") color="${GREEN}" ;;
        "WARNING") color="${YELLOW}" ;;
        "ERROR") color="${RED}" ;;
        *) color="${NC}" ;;
    esac
    
    # Affichage console selon niveau configuré
    if [[ "$ENABLE_LOGGING" == true ]]; then
        case "$LOG_LEVEL" in
            "DEBUG") 
                echo -e "${color}[$timestamp] [$level] $message${NC}" ;;
            "INFO") 
                if [[ "$level" != "DEBUG" ]]; then
                    echo -e "${color}[$timestamp] [$level] $message${NC}"
                fi
                ;;
            "WARNING") 
                if [[ "$level" != "DEBUG" && "$level" != "INFO" ]]; then
                    echo -e "${color}[$timestamp] [$level] $message${NC}"
                fi
                ;;
            "ERROR") 
                if [[ "$level" == "ERROR" ]]; then
                    echo -e "${color}[$timestamp] [$level] $message${NC}"
                fi
                ;;
        esac
        
        # Enregistrement dans le fichier de log
        if [[ ! -d "$LOG_DIR" ]]; then
            mkdir -p "$LOG_DIR"
        fi
        
        echo "[$timestamp] [$level] $message" >> "$LOG_DIR/siteweb-manager.log"
        
        # Rotation des logs si nécessaire
        if [[ "$ROTATE_LOGS" == true && -f "$LOG_DIR/siteweb-manager.log" ]]; then
            local log_size=$(du -m "$LOG_DIR/siteweb-manager.log" 2>/dev/null | cut -f1)
            if [[ -n "$log_size" && "$log_size" -gt "$MAX_LOG_SIZE_MB" ]]; then
                mv "$LOG_DIR/siteweb-manager.log" "$LOG_DIR/siteweb-manager.log.$(date +'%Y%m%d%H%M%S')"
                touch "$LOG_DIR/siteweb-manager.log"
                log "INFO" "Rotation des logs effectuée"
            fi
        fi
    fi
}

# Alias pour les différents niveaux de log
log_debug() { log "DEBUG" "$1"; }
log_info() { log "INFO" "$1"; }
log_warning() { log "WARNING" "$1"; }
log_error() { log "ERROR" "$1"; }

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fonction pour vérifier les prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    # Vérifier si le script est exécuté avec sudo
    if [[ $EUID -ne 0 ]]; then
        log_error "Ce script doit être exécuté avec des privilèges sudo."
        exit 1
    fi
    
    # Vérifier que nous sommes sur un système Debian/Ubuntu
    if ! command_exists apt; then
        log_error "Ce script nécessite un système basé sur Debian/Ubuntu."
        exit 1
    fi
    
    # Vérifier les commandes essentielles
    local required_commands=("grep" "awk" "sed")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    
    # Vérifier et installer les outils de réseau
    if ! command_exists netstat; then
        log_warning "Commande netstat non trouvée. Installation de net-tools..."
        apt update -qq
        apt install -y net-tools
    fi
    
    # Vérifier et installer les outils DNS
    if ! command_exists host; then
        log_warning "Commande host non trouvée. Installation de dnsutils..."
        apt update -qq
        apt install -y dnsutils
    fi
    
    # Vérifier les outils optionnels
    if ! command_exists curl; then
        log_warning "curl non trouvé. Certaines fonctionnalités pourraient être limitées."
    fi
    
    log_info "Prérequis vérifiés avec succès."
}

# Obtenir l'adresse IP du serveur (externe de préférence)
get_server_ip() {
    local server_ip=""
    
    # Essayer d'obtenir l'IP externe
    if command_exists curl; then
        server_ip=$(curl -s ifconfig.me 2>/dev/null)
    elif command_exists wget; then
        server_ip=$(wget -qO- ifconfig.me 2>/dev/null)
    fi
    
    # Si impossible d'obtenir l'IP externe, utiliser l'IP interne principale
    if [ -z "$server_ip" ]; then
        server_ip=$(hostname -I | awk '{print $1}')
    fi
    
    echo "$server_ip"
}

# Fonction pour valider un nom de domaine
validate_domain() {
    local domain=$1
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi
    return 0
}

# Valider un port réseau
validate_port() {
    local port="$1"
    
    # Vérifier que le port est un nombre
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        return 1
    fi
    
    # Vérifier que le port est dans la plage valide (1-65535)
    if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi
    
    return 0
}

# Fonction pour créer une sauvegarde d'un fichier
backup_file() {
    local file=$1
    local backup_dir="$BACKUP_DIR"
    local timestamp=$(date +'%Y%m%d%H%M%S')
    local backup_file="$backup_dir/$(basename "$file").$timestamp"
    
    if [[ ! -d "$backup_dir" ]]; then
        mkdir -p "$backup_dir"
    fi
    
    if [[ -f "$file" ]]; then
        cp "$file" "$backup_file"
        log_info "Sauvegarde créée: $backup_file"
        return 0
    else
        log_warning "Impossible de sauvegarder. Le fichier n'existe pas: $file"
        return 1
    fi
}

# Fonction pour afficher une barre de progression
show_progress() {
    local current=$1
    local total=$2
    local width=${3:-50}
    local percent=$((current * 100 / total))
    local completed=$((width * current / total))
    
    # Construire la barre de progression
    local bar=""
    for ((i=0; i<completed; i++)); do
        bar+="="
    done
    for ((i=completed; i<width; i++)); do
        bar+=" "
    done
    
    # Afficher la barre
    echo -ne "\r[${bar}] ${percent}%"
    if [ "$current" -eq "$total" ]; then
        echo -e "\n"
    fi
}

# Fonction pour demander confirmation
confirm_action() {
    local message=${1:-"Voulez-vous continuer?"}
    local default=${2:-"n"}
    
    local prompt
    if [[ "$default" == "o" ]]; then
        prompt="$message [O/n] "
    else
        prompt="$message [o/N] "
    fi
    
    read -p "$prompt" response
    response=${response:-$default}
    
    if [[ "$response" =~ ^([oO][uU][iI]|[oO])$ ]]; then
        return 0
    else
        return 1
    fi
}

# Fonction pour générer un mot de passe aléatoire sécurisé
generate_password() {
    local length=${1:-16}
    local password=$(< /dev/urandom tr -dc 'A-Za-z0-9!@#$%^&*()_+?><~' | head -c "$length")
    echo "$password"
}

# Fonction pour échapper les caractères spéciaux dans une chaîne
escape_string() {
    local string="$1"
    echo "$string" | sed 's/\\/\\\\/g;s/\//\\\//g;s/&/\\&/g;s/\$/\\$/g'
}

# Fonction pour afficher l'aide
show_help() {
    echo -e "${BLUE}SiteWeb Manager${NC} - Version ${GREEN}$VERSION${NC}"
    echo -e "Outil de gestion de serveur web pour les systèmes Debian/Ubuntu"
    echo ""
    echo -e "${YELLOW}Usage:${NC} $0 [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  -h, --help      Affiche cette aide"
    echo -e "  -v, --version   Affiche la version du script"
    echo ""
    echo -e "${YELLOW}Exemples:${NC}"
    echo -e "  $0               Lance l'interface interactive"
    echo -e "  $0 --version     Affiche la version du script"
    echo ""
} 