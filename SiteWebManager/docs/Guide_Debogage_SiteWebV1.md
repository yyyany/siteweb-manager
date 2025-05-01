# Guide de Débogage - SiteWebV1.sh

## Problèmes courants et solutions

Ce guide vous aidera à résoudre les problèmes les plus fréquemment rencontrés lors de l'utilisation du script SiteWebV1.sh.

### 1. Apache ne démarre pas

#### Symptômes
- Message d'erreur lors du démarrage d'Apache
- Le statut indique que le service est inactif

#### Solutions
1. **Vérifier les erreurs de configuration**
   ```bash
   sudo apache2ctl configtest
   ```
   Si des erreurs sont signalées, corriger le fichier de configuration concerné.

2. **Vérifier les conflits de ports**
   ```bash
   sudo netstat -tuln | grep -E ":80|:443"
   ```
   Si un autre service utilise ces ports, arrêtez-le ou reconfigurer Apache pour utiliser d'autres ports.

3. **Vérifier les journaux Apache**
   ```bash
   sudo tail -n 50 /var/log/apache2/error.log
   ```
   Analyser les messages d'erreur pour identifier le problème.

### 2. Échec de configuration HTTPS

#### Symptômes
- Erreur lors de l'exécution de Certbot
- Le site reste en HTTP malgré la configuration

#### Solutions
1. **Vérifier la propagation DNS**
   Utilisez l'option "Vérifier les DNS" dans le menu du script.
   Si les DNS ne sont pas correctement configurés, attendez leur propagation (jusqu'à 48h).

2. **Vérifier le pare-feu**
   ```bash
   sudo ufw status
   ```
   Assurez-vous que le port 443 est ouvert:
   ```bash
   sudo ufw allow 443/tcp
   ```

3. **Vérifier les journaux de Certbot**
   ```bash
   sudo cat /var/log/letsencrypt/letsencrypt.log
   ```
   Recherchez les erreurs spécifiques.

4. **Forcer le renouvellement du certificat**
   ```bash
   sudo certbot --apache -d votre-domaine.com -d www.votre-domaine.com --force-renewal
   ```

### 3. Site web non accessible

#### Symptômes
- Le site ne s'affiche pas dans le navigateur
- Erreur 404, 403 ou "Unable to connect"

#### Solutions
1. **Vérifier que le site est activé**
   ```bash
   ls -l /etc/apache2/sites-enabled/
   ```
   Si votre configuration n'apparaît pas, utilisez l'option "Vérifier/Réparer un site" dans le menu.

2. **Vérifier les permissions**
   ```bash
   ls -la /var/www/votre-site/
   ```
   Les permissions doivent être 755 et l'utilisateur/groupe www-data.
   Corriger si nécessaire:
   ```bash
   sudo chown -R www-data:www-data /var/www/votre-site/
   sudo chmod -R 755 /var/www/votre-site/
   ```

3. **Vérifier la présence d'un fichier index**
   Assurez-vous qu'un fichier index.html ou index.php existe dans le répertoire du site.

4. **Utiliser l'outil de diagnostic intégré**
   Exécutez l'option "Vérifier/Réparer un site" du script pour diagnostiquer et réparer automatiquement les problèmes courants.

### 4. Module SSL non chargé

#### Symptômes
- Erreur mentionnant que le module SSL n'est pas disponible
- Échec lors de l'activation du HTTPS

#### Solutions
1. **Activer le module manuellement**
   ```bash
   sudo a2enmod ssl
   sudo systemctl restart apache2
   ```

2. **Vérifier l'installation d'Apache**
   ```bash
   sudo apt install --reinstall apache2
   ```

3. **Utiliser l'outil de diagnostic SSL**
   Exécutez l'option "Diagnostic SSL/HTTPS" du script pour résoudre automatiquement les problèmes de SSL.

### 5. Erreurs après mise à jour système

#### Symptômes
- Apache ou les sites ne fonctionnent plus après une mise à jour
- Messages d'erreur concernant des modules ou des dépendances

#### Solutions
1. **Reconfigurez Apache**
   ```bash
   sudo dpkg --configure -a
   sudo apt --fix-broken install
   ```

2. **Vérifier la version de PHP**
   Si des mises à jour de PHP ont été appliquées, vérifiez la compatibilité avec votre configuration Apache.

3. **Redémarrer le serveur**
   Dans certains cas, un redémarrage complet peut résoudre les problèmes:
   ```bash
   sudo reboot
   ```

### 6. Problèmes de permissions 

#### Symptômes
- Erreurs 403 Forbidden
- Impossibilité d'accéder à certains fichiers ou dossiers

#### Solutions
1. **Vérifier les permissions**
   ```bash
   ls -la /var/www/votre-site/
   ```

2. **Corriger les permissions récursivement**
   ```bash
   sudo find /var/www/votre-site/ -type d -exec chmod 755 {} \;
   sudo find /var/www/votre-site/ -type f -exec chmod 644 {} \;
   sudo chown -R www-data:www-data /var/www/votre-site/
   ```

3. **Vérifier la configuration .htaccess**
   Si votre site utilise des fichiers .htaccess, vérifiez qu'ils sont correctement configurés et que la directive AllowOverride est définie sur All.

## Commandes utiles pour le débogage

```bash
# Vérifier la syntaxe des configurations Apache
sudo apache2ctl configtest

# Afficher l'état du service Apache
sudo systemctl status apache2

# Consulter les logs d'erreur Apache
sudo tail -f /var/log/apache2/error.log

# Vérifier les ports en écoute
sudo netstat -tuln

# Vérifier la configuration des sites activés
ls -l /etc/apache2/sites-enabled/

# Vérifier les modules Apache actifs
apache2ctl -M

# Vérifier les certificats SSL installés
sudo certbot certificates

# Tester manuellement un enregistrement DNS
host votre-domaine.com
```

## Contact pour support

Si vous ne parvenez pas à résoudre le problème avec ce guide, consultez la documentation complète ou utilisez les outils intégrés de diagnostic et de réparation du script.

Pour un support avancé, n'hésitez pas à contacter l'administrateur système.
