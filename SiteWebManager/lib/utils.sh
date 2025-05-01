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
        if [[ -f "$LOG_DIR/siteweb-manager.log" ]]; then
            local log_size=$(du -m "$LOG_DIR/siteweb-manager.log" | cut -f1)
            if (( log_size > MAX_LOG_SIZE_MB )); then
                mv "$LOG_DIR/siteweb-manager.log" "$LOG_DIR/siteweb-manager.log.$(date +'%Y%m%d%H%M%S')"
                touch "$LOG_DIR/siteweb-manager.log"
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
    if ! command_exists apt-get; then
        log_error "Ce script nécessite un système basé sur Debian/Ubuntu."
        exit 1
    fi
    
    # Vérifier les commandes essentielles
    local required_commands=("grep" "awk" "sed" "netstat" "host")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_warning "Commandes manquantes: ${missing_commands[*]}"
        log_info "Installation des dépendances manquantes..."
        
        # Installer net-tools si netstat manquant
        if [[ " ${missing_commands[*]} " =~ " netstat " ]]; then
            apt-get update
            apt-get install -y net-tools
        fi
        
        # Installer dnsutils ou bind9-utils si host manquant
        if [[ " ${missing_commands[*]} " =~ " host " ]]; then
            apt-get update
            apt-get install -y dnsutils
        fi
    fi
    
    log_info "Prérequis vérifiés avec succès."
}

# Fonction pour obtenir l'adresse IP du serveur
get_server_ip() {
    hostname -I | cut -d' ' -f1
}

# Fonction pour valider un nom de domaine
validate_domain() {
    local domain=$1
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi
    return 0
}

# Fonction pour valider un numéro de port
validate_port() {
    local port=$1
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        return 1
    fi
    return 0
}

# Fonction pour créer une sauvegarde d'un fichier
backup_file() {
    local file=$1
    local backup_dir="$LOG_DIR/backups"
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