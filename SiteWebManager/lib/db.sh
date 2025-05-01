#!/bin/bash
# Fonctions de gestion de base de données

# Installer MariaDB
install_mariadb() {
    log_info "Installation de MariaDB..."
    
    # Mise à jour des paquets
    apt update
    
    # Installation de MariaDB
    if apt install -y mariadb-server; then
        log_info "MariaDB installé avec succès"
        
        # Sécuriser l'installation
        log_info "Sécurisation de l'installation MariaDB..."
        secure_mariadb
        
        # Activer et démarrer le service
        systemctl enable mariadb
        systemctl start mariadb
        
        log_info "MariaDB configuré et démarré"
        return 0
    else
        log_error "Échec de l'installation de MariaDB"
        return 1
    fi
}

# Sécuriser l'installation MariaDB
secure_mariadb() {
    log_info "Exécution du script de sécurisation MariaDB..."
    
    # Génération d'un mot de passe root aléatoire
    local root_pw=$(openssl rand -base64 16)
    
    # Création du fichier de configuration pour mysql_secure_installation
    cat > /tmp/mysql_secure_installation.sql << EOF
-- Change root password
UPDATE mysql.user SET Password=PASSWORD('${root_pw}') WHERE User='root';
-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';
-- Disallow remote root login
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- Reload privilege tables
FLUSH PRIVILEGES;
EOF

    # Exécution du script
    mysql < /tmp/mysql_secure_installation.sql
    
    # Suppression du fichier temporaire
    rm -f /tmp/mysql_secure_installation.sql
    
    # Sauvegarde du mot de passe dans un fichier sécurisé
    echo "MariaDB Root Password: $root_pw" > /root/.mariadb_root
    chmod 600 /root/.mariadb_root
    
    log_info "Installation MariaDB sécurisée. Mot de passe root sauvegardé dans /root/.mariadb_root"
}

# Créer une base de données
create_database() {
    local db_name=$1
    local db_user=$2
    local db_password=$3
    
    # Validation des paramètres
    if [[ -z "$db_name" || -z "$db_user" || -z "$db_password" ]]; then
        log_error "Paramètres manquants pour la création de la base de données"
        return 1
    fi
    
    log_info "Création de la base de données $db_name pour l'utilisateur $db_user..."
    
    # Récupération du mot de passe root
    local root_pw=""
    if [[ -f /root/.mariadb_root ]]; then
        root_pw=$(grep "MariaDB Root Password" /root/.mariadb_root | cut -d' ' -f4)
    fi
    
    # Création de la base et de l'utilisateur
    if [[ -n "$root_pw" ]]; then
        mysql -u root -p"$root_pw" << EOF
CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
EOF
    else
        mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS \`$db_name\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$db_user'@'localhost' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON \`$db_name\`.* TO '$db_user'@'localhost';
FLUSH PRIVILEGES;
EOF
    fi
    
    if [[ $? -eq 0 ]]; then
        log_info "Base de données $db_name et utilisateur $db_user créés avec succès"
        return 0
    else
        log_error "Échec de la création de la base de données"
        return 1
    fi
}

# Lister les bases de données
list_databases() {
    log_info "Liste des bases de données..."
    
    # Récupération du mot de passe root
    local root_pw=""
    if [[ -f /root/.mariadb_root ]]; then
        root_pw=$(grep "MariaDB Root Password" /root/.mariadb_root | cut -d' ' -f4)
    fi
    
    # Afficher la liste des bases
    echo -e "${BLUE}=== Bases de données ===${NC}"
    
    if [[ -n "$root_pw" ]]; then
        mysql -u root -p"$root_pw" -e "SHOW DATABASES;" | grep -v "Database\|information_schema\|mysql\|performance_schema"
    else
        mysql -u root -e "SHOW DATABASES;" | grep -v "Database\|information_schema\|mysql\|performance_schema"
    fi
}

# Supprimer une base de données
drop_database() {
    local db_name=$1
    
    # Validation du nom de la base
    if [[ -z "$db_name" ]]; then
        log_error "Nom de la base de données manquant"
        return 1
    fi
    
    log_info "Suppression de la base de données $db_name..."
    
    # Récupération du mot de passe root
    local root_pw=""
    if [[ -f /root/.mariadb_root ]]; then
        root_pw=$(grep "MariaDB Root Password" /root/.mariadb_root | cut -d' ' -f4)
    fi
    
    # Suppression de la base
    if [[ -n "$root_pw" ]]; then
        mysql -u root -p"$root_pw" -e "DROP DATABASE IF EXISTS \`$db_name\`;"
    else
        mysql -u root -e "DROP DATABASE IF EXISTS \`$db_name\`;"
    fi
    
    if [[ $? -eq 0 ]]; then
        log_info "Base de données $db_name supprimée avec succès"
        return 0
    else
        log_error "Échec de la suppression de la base de données"
        return 1
    fi
}

# Sauvegarder une base de données
backup_database() {
    local db_name=$1
    local backup_dir=$2
    
    # Validation des paramètres
    if [[ -z "$db_name" ]]; then
        log_error "Nom de la base de données manquant"
        return 1
    fi
    
    # Définition du répertoire de sauvegarde par défaut
    if [[ -z "$backup_dir" ]]; then
        backup_dir="/var/backups/mysql"
    fi
    
    # Création du répertoire de sauvegarde
    mkdir -p "$backup_dir"
    
    # Génération du nom de fichier de sauvegarde
    local timestamp=$(date +'%Y%m%d%H%M%S')
    local backup_file="$backup_dir/$db_name.$timestamp.sql.gz"
    
    log_info "Sauvegarde de la base de données $db_name dans $backup_file..."
    
    # Récupération du mot de passe root
    local root_pw=""
    if [[ -f /root/.mariadb_root ]]; then
        root_pw=$(grep "MariaDB Root Password" /root/.mariadb_root | cut -d' ' -f4)
    fi
    
    # Sauvegarde de la base
    if [[ -n "$root_pw" ]]; then
        mysqldump -u root -p"$root_pw" "$db_name" | gzip > "$backup_file"
    else
        mysqldump -u root "$db_name" | gzip > "$backup_file"
    fi
    
    if [[ $? -eq 0 ]]; then
        log_info "Sauvegarde de $db_name terminée avec succès"
        return 0
    else
        log_error "Échec de la sauvegarde de la base de données"
        return 1
    fi
}

# Restaurer une base de données
restore_database() {
    local db_name=$1
    local backup_file=$2
    
    # Validation des paramètres
    if [[ -z "$db_name" || -z "$backup_file" ]]; then
        log_error "Paramètres manquants pour la restauration"
        return 1
    fi
    
    # Vérification de l'existence du fichier de sauvegarde
    if [[ ! -f "$backup_file" ]]; then
        log_error "Le fichier de sauvegarde n'existe pas: $backup_file"
        return 1
    fi
    
    log_info "Restauration de la base de données $db_name depuis $backup_file..."
    
    # Récupération du mot de passe root
    local root_pw=""
    if [[ -f /root/.mariadb_root ]]; then
        root_pw=$(grep "MariaDB Root Password" /root/.mariadb_root | cut -d' ' -f4)
    fi
    
    # Restauration de la base
    if [[ -n "$root_pw" ]]; then
        gunzip -c "$backup_file" | mysql -u root -p"$root_pw" "$db_name"
    else
        gunzip -c "$backup_file" | mysql -u root "$db_name"
    fi
    
    if [[ $? -eq 0 ]]; then
        log_info "Restauration de $db_name terminée avec succès"
        return 0
    else
        log_error "Échec de la restauration de la base de données"
        return 1
    fi
} 