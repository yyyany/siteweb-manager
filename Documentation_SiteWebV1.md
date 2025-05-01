# Documentation SiteWebV1.sh

## Présentation générale

**SiteWebV1.sh** est un script Bash (version actuelle : 1.21) conçu pour simplifier la gestion d'un serveur web sous Linux. Ce script permet d'automatiser l'installation, la configuration et la maintenance des composants essentiels d'un serveur web, principalement Apache.

## Fonctionnalités principales

Le script offre les fonctionnalités suivantes, organisées par menus :

### 1. Mise à jour du système Linux
- Mise à jour de la liste des paquets
- Installation des mises à jour
- Nettoyage des paquets obsolètes

### 2. Gestion d'Apache
- Installation d'Apache
- Démarrage, arrêt et redémarrage du service
- Affichage du statut (avec détection et installation automatique de net-tools)
- Activation automatique du module SSL

### 3. Configuration d'Apache
- Édition de la configuration principale
- Vérification de la syntaxe
- Gestion des modules
- Gestion des sites virtuels
- Modification du port SSH
- Configuration des règles de pare-feu pour les ports HTTP/HTTPS

### 4. Gestion des sites web
- Déploiement de nouveaux sites
- Affichage de la liste des sites déployés
- Suppression de sites
- Configuration HTTPS (avec Certbot)
- Vérification et réparation des sites
- Diagnostic SSL/HTTPS
- Vérification des DNS

## Utilisation détaillée

### Installation et démarrage

Le script s'exécute avec la commande :
```bash
sudo bash SiteWebV1.sh
```

### Menu principal

Le menu principal propose les options suivantes :
1. Mise à jour de Linux
2. Installation Apache
3. Gestion des sites web
4. Informations système
5. Option personnalisée
0. Quitter

### Déploiement d'un site web

La procédure de déploiement comprend :
1. Sélection du dossier contenant les fichiers du site
2. Définition d'un nom de domaine
3. Création automatique de la configuration Apache
4. Configuration des permissions appropriées
5. Activation du site

### Configuration HTTPS

Le script intègre une gestion complète du HTTPS via Let's Encrypt :
1. Installation de Certbot si nécessaire
2. Vérification des enregistrements DNS
3. Obtention et configuration des certificats SSL
4. Renouvellement automatique

## Fonctionnalités avancées

### Vérification et réparation des sites

Le script peut diagnostiquer et réparer les problèmes courants :
- Vérification des dossiers dans /var/www/
- Vérification des configurations Apache
- Vérification de l'activation des sites
- Tests de syntaxe
- Création automatique des éléments manquants

### Diagnostic SSL/HTTPS

Un outil de diagnostic complet pour résoudre les problèmes SSL :
1. Vérification du module SSL
2. Vérification du port 443
3. Vérification des certificats
4. Analyse de la configuration Apache SSL
5. Test de la configuration globale

### Vérification DNS

Vérification de la configuration DNS pour un domaine spécifique :
- Affichage des enregistrements DNS requis
- Vérification des enregistrements A pour le domaine et son sous-domaine www
- Instructions pour configurer les DNS

## Notes importantes

- Le script est conçu pour les systèmes Debian/Ubuntu
- Il nécessite des privilèges root (sudo)
- Le mot de passe root par défaut : EcoleDuWebRoot!
- Lors de la modification du port SSH, notez soigneusement le nouveau port
