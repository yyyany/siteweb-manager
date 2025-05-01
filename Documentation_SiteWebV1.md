# Documentation Complète - Script de Gestion de Serveur Web

## Table des matières
1. [Introduction](#introduction)
2. [Architecture du script](#architecture-du-script)
3. [Fonctionnalités principales](#fonctionnalités-principales)
4. [Guide d'installation](#guide-dinstallation)
5. [Guide d'utilisation](#guide-dutilisation)
6. [Débogage et diagnostic](#débogage-et-diagnostic)
7. [Erreurs courantes et solutions](#erreurs-courantes-et-solutions)
8. [Améliorations proposées](#améliorations-proposées)
9. [Restructuration du code](#restructuration-du-code)
10. [Sécurité](#sécurité)
11. [Maintenance et mises à jour](#maintenance-et-mises-à-jour)

## Introduction

Ce document présente une analyse complète du script `SiteWebV1.sh`, un outil de gestion de serveur web développé pour les environnements Linux, spécifiquement orienté vers la gestion des machines virtuelles sur DigitalOcean. Le script offre une interface utilisateur complète pour l'installation, la configuration et la gestion d'Apache ainsi que le déploiement et la maintenance de sites web.

**Version actuelle :** 1.21

Le script permet de :
- Mettre à jour le système Linux
- Installer et configurer Apache
- Déployer des sites web
- Configurer HTTPS avec Let's Encrypt (Certbot)
- Diagnostiquer et réparer les configurations
- Gérer les DNS et vérifier leur propagation

## Architecture du script

### Structure générale

Le script est organisé selon le modèle suivant :
1. **Déclarations initiales** : Version, historique et variables de couleurs
2. **Fonctions utilitaires** : Logging, mise à jour système
3. **Fonctions de gestion Apache** : Installation, démarrage, arrêt, etc.
4. **Fonctions de gestion de sites** : Déploiement, configuration HTTPS, diagnostics
5. **Fonctions d'interface utilisateur** : Menus, sous-menus et navigation
6. **Point d'entrée** : Appel au menu principal

### Organisation des menus

Le script utilise une interface basée sur des menus hiérarchiques :
- Menu principal
  - Mise à jour Linux
  - Menu Apache
    - Installation
    - Gestion du service
    - Configuration
  - Gestion des sites web
    - Déploiement
    - Liste des sites
    - Suppression
    - Configuration HTTPS
    - Diagnostic

### Système de couleurs

Le script utilise un système de couleurs ANSI pour améliorer la lisibilité :
- `GREEN` : Messages de succès
- `BLUE` : Titres et encadrements
- `RED` : Erreurs et avertissements
- `YELLOW` : Prompts et informations importantes
- `NC` : Réinitialisation de la couleur

## Fonctionnalités principales

### Gestion système

- **Mise à jour système** (`update_linux`) : Met à jour la liste des paquets, effectue les mises à niveau et nettoie les paquets obsolètes.

### Gestion d'Apache

- **Installation** (`install_apache`) : Installe le serveur Apache2.
- **Gestion du service** : Démarrage, arrêt, redémarrage, vérification du statut.
- **Configuration avancée** (`configure_apache`) :
  - Édition de la configuration principale
  - Vérification de la syntaxe
  - Gestion des modules
  - Gestion des sites virtuels
  - Configuration des ports SSH/Apache

### Gestion des sites web

- **Déploiement** (`deploy_site`) : Déploie un site web depuis un dossier local vers Apache.
- **Configuration HTTPS** (`configure_https`) : Configure HTTPS avec Let's Encrypt.
- **Vérification DNS** (`check_dns`) : Vérifie la configuration DNS pour un domaine.
- **Diagnostic SSL** (`diagnose_ssl`) : Diagnostique et répare les problèmes SSL.
- **Gestion complète des sites** : Liste, suppression, vérification, réparation.

## Guide d'installation

### Prérequis

- Système d'exploitation Linux (testé sur Ubuntu/Debian)
- Accès root ou privilèges sudo
- Connexion internet active

### Installation

1. Téléchargez le script :
   ```bash
   wget https://example.com/SiteWebV1.sh
   ```

2. Rendez le script exécutable :
   ```bash
   chmod +x SiteWebV1.sh
   ```

3. Exécutez le script :
   ```bash
   ./SiteWebV1.sh
   ```

## Guide d'utilisation

### Mise à jour du système

1. Dans le menu principal, sélectionnez l'option `[1] Mise à jour de linux`.
2. Le script mettra à jour la liste des paquets, effectuera les mises à niveau et nettoiera les paquets obsolètes.

### Installation et configuration d'Apache

1. Dans le menu principal, sélectionnez l'option `[2] Installation Apache`.
2. Choisissez l'option `[1] Installer Apache` pour installer le serveur.
3. Utilisez les autres options pour gérer le service et sa configuration.

### Déploiement d'un site web

1. Dans le menu principal, sélectionnez l'option `[3] Gestion des sites web`.
2. Choisissez l'option `[1] Déployer un nouveau site`.
3. Suivez les instructions pour spécifier le dossier source et le nom de domaine.
4. Le script va :
   - Créer le répertoire approprié sur le serveur
   - Copier les fichiers
   - Configurer les permissions
   - Créer la configuration Apache
   - Activer le site

### Configuration HTTPS

1. Dans le menu de gestion des sites, sélectionnez `[4] Configurer HTTPS`.
2. Entrez le nom de domaine pour lequel vous souhaitez configurer HTTPS.
3. Le script vérifiera les DNS avant de procéder à la configuration avec Certbot.

## Débogage et diagnostic

### Diagnostic des sites web

Le script offre plusieurs outils de diagnostic :

- **Vérification/Réparation de site** (`check_repair_site`) :
  - Vérifie l'existence du dossier dans `/var/www/`
  - Vérifie la configuration Apache
  - Vérifie l'activation du site
  - Propose des réparations automatiques

- **Diagnostic SSL** (`diagnose_ssl`) :
  - Vérifie l'activation du module SSL
  - Vérifie l'ouverture du port 443
  - Vérifie la présence et validité du certificat
  - Vérifie la configuration SSL d'Apache
  - Propose des réparations automatiques

### Vérification des DNS

La fonction `check_dns` permet de vérifier la configuration DNS pour un domaine :
- Vérifie les enregistrements A pour le domaine et son sous-domaine www
- Compare les adresses IP obtenues avec l'IP du serveur
- Fournit des instructions pour la configuration DNS sur IONOS

### Commandes utiles pour le débogage manuel

En cas de problème, voici quelques commandes utiles pour le débogage :

```bash
# Vérifier le statut d'Apache
systemctl status apache2

# Vérifier la syntaxe de la configuration Apache
apache2ctl configtest

# Vérifier les modules actifs
apache2ctl -M

# Vérifier les ports en écoute
netstat -tuln | grep -E ":80|:443"

# Vérifier les certificats Let's Encrypt
certbot certificates
```

## Erreurs courantes et solutions

### Problèmes de DNS

**Symptôme :** Échec de la validation du domaine par Certbot.

**Causes possibles :**
- DNS mal configurés
- Propagation DNS non complète

**Solutions :**
1. Vérifiez la configuration DNS avec l'outil `check_dns`
2. Assurez-vous d'avoir créé les enregistrements A corrects
3. Attendez la propagation DNS (peut prendre jusqu'à 48h)

### Problèmes de permissions

**Symptôme :** Apache ne peut pas accéder aux fichiers du site.

**Causes possibles :**
- Permissions incorrectes sur les fichiers
- Propriétaire/groupe incorrects

**Solutions :**
1. Assurez-vous que les fichiers appartiennent à `www-data:www-data`
2. Appliquez les permissions 755 aux répertoires et 644 aux fichiers

### Problèmes de configuration Apache

**Symptôme :** Erreurs dans les logs Apache ou échec du démarrage.

**Causes possibles :**
- Erreur de syntaxe dans la configuration
- Conflit de ports
- Modules manquants

**Solutions :**
1. Vérifiez la syntaxe avec `apache2ctl configtest`
2. Assurez-vous que les ports nécessaires sont ouverts
3. Activez les modules requis avec `a2enmod`

## Améliorations proposées

### Améliorations fonctionnelles

1. **Gestion de base de données**
   - Ajout de fonctionnalités pour installer et gérer MySQL/MariaDB
   - Création/gestion des bases et utilisateurs

2. **Gestion PHP**
   - Installation et configuration de différentes versions de PHP
   - Gestion des modules PHP

3. **Sauvegarde et restauration**
   - Fonctionnalités de sauvegarde des sites et configurations
   - Restauration de sauvegardes

4. **Surveillance et performances**
   - Intégration d'outils de surveillance (Munin, Nagios)
   - Optimisation des performances d'Apache

### Améliorations techniques

1. **Modularisation**
   - Séparation du code en modules indépendants
   - Utilisation de l'inclusion de fichiers pour une meilleure organisation

2. **Gestion des erreurs**
   - Amélioration du système de gestion des erreurs
   - Journalisation plus détaillée

3. **Tests**
   - Ajout de tests automatisés
   - Validation des configurations

4. **Documentation intégrée**
   - Amélioration de l'aide intégrée
   - Documentation des fonctions dans le code

## Restructuration du code

Pour améliorer la maintenabilité, le script pourrait être restructuré comme suit :

### Architecture proposée

```
SiteWebManager/
├── main.sh                 # Script principal
├── config/                 # Configuration
│   ├── config.sh           # Variables de configuration
│   └── colors.sh           # Définitions des couleurs
├── lib/                    # Bibliothèques de fonctions
│   ├── utils.sh            # Fonctions utilitaires
│   ├── system.sh           # Fonctions système
│   ├── apache.sh           # Fonctions Apache
│   ├── sites.sh            # Fonctions gestion de sites
│   ├── ssl.sh              # Fonctions SSL/HTTPS
│   └── db.sh               # Fonctions base de données (nouvelle)
├── ui/                     # Interface utilisateur
│   ├── menus.sh            # Définitions des menus
│   └── display.sh          # Fonctions d'affichage
└── docs/                   # Documentation
    └── README.md           # Documentation utilisateur
```

### Avantages de cette structure

1. **Séparation des préoccupations** : Chaque fichier a une responsabilité unique
2. **Facilité de maintenance** : Modification d'une fonctionnalité sans impacter les autres
3. **Réutilisabilité** : Possibilité de réutiliser des composants dans d'autres scripts
4. **Extensibilité** : Ajout facile de nouvelles fonctionnalités

## Sécurité

### Points forts actuels

- Utilisation de Certbot pour HTTPS
- Vérification de la configuration avant application
- Sauvegarde des configurations avant modification

### Améliorations de sécurité recommandées

1. **Durcissement d'Apache**
   - Configuration de l'en-tête HSTS
   - Désactivation des modules non nécessaires
   - Configuration de CSP (Content Security Policy)

2. **Pare-feu**
   - Configuration plus détaillée de UFW
   - Limitation des accès par IP

3. **Audit de sécurité**
   - Vérification périodique des permissions
   - Scan de vulnérabilités

4. **Gestion des certificats**
   - Surveillance de l'expiration des certificats
   - Rotation automatique des certificats

## Maintenance et mises à jour

### Bonnes pratiques

1. **Versionnement**
   - Utilisation de Git pour suivre les modifications
   - Tagging des versions

2. **Tests**
   - Test sur environnement de préproduction
   - Tests de régression après modifications

3. **Documentation**
   - Mise à jour de la documentation avec chaque changement
   - Documentation des procédures de rollback

4. **Automatisation**
   - Mise en place de CI/CD
   - Tests automatisés

### Procédure de mise à jour

1. Sauvegarde de la version actuelle
2. Application des modifications
3. Tests
4. Déploiement en production
5. Vérification post-déploiement
6. Mise à jour de la documentation

---

Ce document fournit une analyse complète du script SiteWebV1.sh et propose des améliorations pour en faire un outil professionnel de gestion de serveur web. Les sections suivantes peuvent être développées davantage selon les besoins spécifiques du projet. 