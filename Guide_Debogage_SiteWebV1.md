# Guide de Débogage - Script de Gestion de Serveur Web

## Table des matières
1. [Introduction](#introduction)
2. [Outils de diagnostic](#outils-de-diagnostic)
3. [Problèmes courants et solutions](#problèmes-courants-et-solutions)
4. [Techniques avancées de débogage](#techniques-avancées-de-débogage)
5. [Procédures de récupération](#procédures-de-récupération)
6. [Bonnes pratiques de maintenance](#bonnes-pratiques-de-maintenance)

## Introduction

Ce guide de débogage est conçu pour vous aider à identifier, diagnostiquer et résoudre les problèmes potentiels qui peuvent survenir lors de l'utilisation du script SiteWebV1.sh. Il couvre les problèmes courants liés à Apache, aux certificats SSL, aux DNS et à la configuration générale du serveur.

## Outils de diagnostic

### Commandes natives d'Apache

```bash
# Vérifier le statut d'Apache
systemctl status apache2

# Vérifier la syntaxe de la configuration Apache
apache2ctl configtest

# Lister les modules activés
apache2ctl -M

# Tester la configuration des hôtes virtuels
apache2ctl -S

# Redémarrer Apache proprement
systemctl restart apache2
```

### Journaux système

Les fichiers de logs sont essentiels pour le débogage :

```bash
# Logs d'erreur Apache globaux
tail -n 50 /var/log/apache2/error.log

# Logs d'accès Apache globaux
tail -n 50 /var/log/apache2/access.log

# Logs d'erreur spécifiques à un site
tail -n 50 /var/log/apache2/example.com_error.log

# Logs système
tail -n 50 /var/log/syslog
```

### Outils réseau

```bash
# Vérifier les ports en écoute
netstat -tuln | grep -E ":80|:443"

# Tester la connectivité à un domaine
ping exemple.com

# Vérifier les enregistrements DNS
host exemple.com
dig exemple.com

# Tester la connectivité TCP à un port spécifique
nc -vz exemple.com 443
```

### Outils SSL/TLS

```bash
# Vérifier les certificats Let's Encrypt
certbot certificates

# Tester manuellement un certificat SSL
openssl s_client -connect exemple.com:443

# Vérifier la date d'expiration d'un certificat
echo | openssl s_client -servername exemple.com -connect exemple.com:443 2>/dev/null | openssl x509 -noout -dates
```

## Problèmes courants et solutions

### 1. Apache ne démarre pas

**Symptômes** :
- La commande `systemctl start apache2` échoue
- L'erreur "Failed to start The Apache HTTP Server" apparaît

**Solutions possibles** :

1. **Vérifier les erreurs de syntaxe**
   ```bash
   apache2ctl configtest
   ```
   Si des erreurs sont détectées, corrigez les fichiers de configuration mentionnés.

2. **Vérifier les conflits de ports**
   ```bash
   netstat -tuln | grep -E ":80|:443"
   ```
   Si un autre service utilise déjà ces ports, arrêtez-le ou reconfigurez Apache pour utiliser d'autres ports.

3. **Vérifier les permissions des fichiers**
   ```bash
   ls -la /etc/apache2/
   ls -la /var/www/
   ```
   Assurez-vous que les fichiers appartiennent aux bons utilisateurs et ont les bonnes permissions.

4. **Examiner les journaux d'erreur**
   ```bash
   journalctl -u apache2.service --no-pager
   ```

### 2. Problèmes de configuration HTTPS (SSL/TLS)

**Symptômes** :
- Erreurs de certificat dans le navigateur
- Certbot échoue à créer ou renouveler les certificats
- Site accessible en HTTP mais pas en HTTPS

**Solutions possibles** :

1. **Vérifier les certificats existants**
   ```bash
   certbot certificates
   ```

2. **Vérifier les configurations SSL dans Apache**
   ```bash
   grep -r "SSLCertificateFile" /etc/apache2/
   ```

3. **Forcer le renouvellement d'un certificat**
   ```bash
   certbot renew --force-renewal --cert-name exemple.com
   ```

4. **Recréer un certificat**
   ```bash
   certbot --apache -d exemple.com -d www.exemple.com
   ```

5. **Vérifier les modules SSL**
   ```bash
   apache2ctl -M | grep ssl
   ```
   Si le module ssl n'est pas listé, activez-le :
   ```bash
   a2enmod ssl
   systemctl restart apache2
   ```

### 3. Problèmes DNS

**Symptômes** :
- Échecs lors de la validation du domaine par Certbot
- Site inaccessible via le nom de domaine mais accessible via IP

**Solutions possibles** :

1. **Vérifier les enregistrements DNS actuels**
   ```bash
   host exemple.com
   host www.exemple.com
   ```

2. **Comparer avec l'IP du serveur**
   ```bash
   hostname -I
   ```
   Vérifiez que l'IP renvoyée par les commandes `host` correspond à l'IP de votre serveur.

3. **Vérifier la propagation DNS**
   ```bash
   dig +trace exemple.com
   ```
   Si les DNS ne sont pas encore propagés, attendez quelques heures (jusqu'à 48h dans certains cas).

4. **Tester localement en modifiant /etc/hosts**
   ```bash
   echo "123.45.67.89 exemple.com www.exemple.com" >> /etc/hosts
   ```
   Remplacez l'IP par celle de votre serveur pour tester sans attendre la propagation DNS.

### 4. Problèmes de permission et d'accès aux fichiers

**Symptômes** :
- Erreurs 403 Forbidden
- Erreurs 500 Internal Server Error
- Apache ne peut pas lire les fichiers du site

**Solutions possibles** :

1. **Vérifier le propriétaire et les permissions**
   ```bash
   ls -la /var/www/exemple.com/
   ```

2. **Corriger le propriétaire**
   ```bash
   chown -R www-data:www-data /var/www/exemple.com/
   ```

3. **Corriger les permissions**
   ```bash
   find /var/www/exemple.com/ -type d -exec chmod 755 {} \;
   find /var/www/exemple.com/ -type f -exec chmod 644 {} \;
   ```

4. **Vérifier les logs spécifiques au site**
   ```bash
   tail -n 50 /var/log/apache2/exemple.com_error.log
   ```

## Techniques avancées de débogage

### Débogage en mode verbeux

Pour obtenir plus d'informations lors de l'exécution de commandes critiques :

1. **Apache en mode verbeux**
   ```bash
   apache2ctl -t -D DUMP_VHOSTS
   ```

2. **Certbot en mode verbeux**
   ```bash
   certbot --apache -d exemple.com --verbose
   ```

3. **Vérification SSL approfondie**
   ```bash
   openssl s_client -connect exemple.com:443 -servername exemple.com -showcerts
   ```

### Simulation et tests

1. **Tester un hôte virtuel sans redémarrer Apache**
   ```bash
   curl -H "Host: exemple.com" http://localhost/
   ```

2. **Simulation de requête SSL**
   ```bash
   openssl s_client -connect exemple.com:443 -servername exemple.com
   ```
   Puis tapez :
   ```
   GET / HTTP/1.1
   Host: exemple.com
   
   ```
   (Appuyez deux fois sur Entrée après "Host: exemple.com")

3. **Test d'un certificat avant installation**
   ```bash
   certbot certonly --dry-run -d exemple.com
   ```

## Procédures de récupération

### Récupération d'une configuration Apache cassée

1. **Restaurer la configuration par défaut**
   ```bash
   cp /etc/apache2/apache2.conf.dpkg-dist /etc/apache2/apache2.conf
   ```

2. **Désactiver tous les sites personnalisés**
   ```bash
   a2dissite $(ls /etc/apache2/sites-enabled/ | grep -v "000-default.conf")
   ```

3. **Réactiver uniquement le site par défaut**
   ```bash
   a2ensite 000-default.conf
   ```

4. **Redémarrer Apache**
   ```bash
   systemctl restart apache2
   ```

### Récupération après échec de Certbot

1. **Examiner les journaux de Certbot**
   ```bash
   tail -n 100 /var/log/letsencrypt/letsencrypt.log
   ```

2. **Supprimer une configuration SSL problématique**
   ```bash
   rm /etc/apache2/sites-available/exemple.com-le-ssl.conf
   rm /etc/apache2/sites-enabled/exemple.com-le-ssl.conf
   ```

3. **Revenir à la configuration HTTP uniquement**
   ```bash
   a2dissite exemple.com-le-ssl
   a2ensite exemple.com
   systemctl restart apache2
   ```

4. **Nettoyer et réessayer avec Certbot**
   ```bash
   certbot delete --cert-name exemple.com
   certbot --apache -d exemple.com -d www.exemple.com
   ```

### Récupération d'un système de fichiers corrompu

1. **Vérifier l'intégrité des fichiers du site**
   ```bash
   find /var/www/exemple.com -type f -name "*.php" -exec php -l {} \; | grep -v "No syntax errors"
   ```

2. **Restaurer à partir d'une sauvegarde**
   ```bash
   cp -r /chemin/vers/sauvegarde/exemple.com/* /var/www/exemple.com/
   chown -R www-data:www-data /var/www/exemple.com/
   ```

## Bonnes pratiques de maintenance

### 1. Sauvegardes régulières

```bash
# Créer un script de sauvegarde quotidienne
cat > /usr/local/bin/backup-websites.sh << 'EOL'
#!/bin/bash
DATE=$(date +%Y-%m-%d)
BACKUP_DIR="/var/backups/websites/$DATE"

# Créer le répertoire de sauvegarde
mkdir -p "$BACKUP_DIR"

# Sauvegarder tous les sites
for site in /var/www/*/; do
    site_name=$(basename "$site")
    echo "Sauvegarde de $site_name..."
    tar -czf "$BACKUP_DIR/$site_name.tar.gz" -C /var/www "$site_name"
done

# Sauvegarder la configuration Apache
tar -czf "$BACKUP_DIR/apache2-config.tar.gz" -C /etc apache2

# Sauvegarder les certificats Let's Encrypt
tar -czf "$BACKUP_DIR/letsencrypt.tar.gz" -C /etc letsencrypt

# Rotation des sauvegardes (garder 30 jours)
find /var/backups/websites -type d -mtime +30 -exec rm -rf {} \; 2>/dev/null || true

echo "Sauvegarde terminée dans $BACKUP_DIR"
EOL

chmod +x /usr/local/bin/backup-websites.sh

# Ajouter au cron pour exécution quotidienne
echo "0 3 * * * root /usr/local/bin/backup-websites.sh" > /etc/cron.d/backup-websites
```

### 2. Surveillance de la santé du serveur

```bash
# Installer et configurer un utilitaire de surveillance comme Monit
apt update
apt install -y monit

# Configuration de base pour surveiller Apache
cat > /etc/monit/conf.d/apache2 << 'EOL'
check process apache2 with pidfile /var/run/apache2/apache2.pid
    start program = "/etc/init.d/apache2 start"
    stop program = "/etc/init.d/apache2 stop"
    if failed host 127.0.0.1 port 80 protocol http then restart
    if 5 restarts within 5 cycles then timeout
EOL

# Redémarrer Monit
systemctl restart monit
```

### 3. Mise à jour automatique des certificats

Certbot installe automatiquement un timer systemd pour vérifier et renouveler les certificats, mais vérifiez qu'il est actif :

```bash
systemctl status certbot.timer
```

Si nécessaire, activez-le :

```bash
systemctl enable certbot.timer
systemctl start certbot.timer
```

### 4. Vérification périodique des logs

Créez un script pour analyser les logs et vous alerter des problèmes :

```bash
cat > /usr/local/bin/check-apache-logs.sh << 'EOL'
#!/bin/bash
LOG_FILE="/var/log/apache2/error.log"
EMAIL="admin@exemple.com"

# Rechercher les erreurs critiques des dernières 24 heures
ERRORS=$(grep -i "error\|critical\|alert\|emergency" "$LOG_FILE" | grep -v "notice" | grep "$(date --date="24 hours ago" +"%Y-%m-%d")")

if [ ! -z "$ERRORS" ]; then
    echo "Erreurs Apache détectées dans les dernières 24 heures :" | mail -s "Alerte Apache" "$EMAIL" << EOF
$ERRORS
EOF
fi
EOL

chmod +x /usr/local/bin/check-apache-logs.sh

# Ajouter au cron pour vérification quotidienne
echo "0 8 * * * root /usr/local/bin/check-apache-logs.sh" > /etc/cron.d/check-apache-logs
```

---

Ce guide de débogage vous fournit les outils et les techniques nécessaires pour identifier, diagnostiquer et résoudre les problèmes courants liés à l'utilisation du script SiteWebV1.sh. En suivant ces procédures et bonnes pratiques, vous serez en mesure de maintenir votre serveur web en parfait état de fonctionnement. 