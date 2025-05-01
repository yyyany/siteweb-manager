# SiteWeb Manager

SiteWeb Manager est un outil de gestion de sites web et de services associés pour les systèmes Linux. Il permet de gérer facilement les sites web, les bases de données, PHP et les configurations système.

## Fonctionnalités

### Gestion des sites web
- Déploiement de sites web
- Liste des sites déployés
- Suppression de sites
- Vérification et réparation de sites

### Gestion des bases de données
- Installation de MariaDB
- Création de bases de données
- Gestion des utilisateurs
- Sauvegarde et restauration

### Gestion de PHP
- Installation de PHP et des extensions
- Installation de Composer
- Optimisation des performances
- Gestion des versions

### Gestion du système
- Mises à jour système
- Configuration du pare-feu
- Informations système

### Configuration
- Paramètres personnalisables
- Restauration des paramètres par défaut

## Prérequis

- Système d'exploitation : Debian/Ubuntu
- Droits d'administration (sudo)
- Connexion Internet

## Installation

1. Clonez le dépôt :
```bash
git clone https://github.com/yyyany/siteweb-manager.git
cd siteweb-manager
```

2. Rendez le script exécutable :
```bash
chmod +x siteweb-manager.sh
```

3. Lancez l'application :
```bash
./siteweb-manager.sh
```

## Structure du projet

```
SiteWebManager/
├── config/
│   ├── config.sh      # Configuration globale
│   └── colors.sh      # Définitions des couleurs
├── lib/
│   ├── utils.sh       # Fonctions utilitaires
│   ├── system.sh      # Gestion du système
│   ├── apache.sh      # Gestion d'Apache
│   ├── sites.sh       # Gestion des sites web
│   ├── ssl.sh         # Gestion SSL
│   ├── db.sh          # Gestion des bases de données
│   └── php.sh         # Gestion de PHP
├── ui/
│   ├── display.sh     # Fonctions d'affichage
│   └── menus.sh       # Menus de l'application
├── tests/             # Tests unitaires
├── docs/              # Documentation
├── siteweb-manager.sh # Script principal
└── README.md          # Documentation
```

## Utilisation

1. Lancez l'application :
```bash
./siteweb-manager.sh
```

2. Utilisez les menus pour naviguer dans les différentes fonctionnalités.

3. Suivez les instructions à l'écran pour effectuer les opérations souhaitées.

## Configuration

La configuration se fait dans le fichier `config/config.sh`. Vous pouvez modifier :
- Les chemins des répertoires
- Les ports par défaut
- Les options de déploiement
- Les paramètres de journalisation
- Les paramètres de mise à jour automatique

## Sécurité

- Les mots de passe sont stockés de manière sécurisée
- Les connexions à distance sont désactivées par défaut
- Les paramètres de sécurité sont optimisés
- Les journaux sont conservés pour le suivi

## Maintenance

### Mises à jour
L'application vérifie automatiquement les mises à jour disponibles. Vous pouvez également les vérifier manuellement via le menu Configuration.

### Sauvegarde
Il est recommandé de sauvegarder régulièrement :
- Les fichiers de configuration
- Les bases de données
- Les sites web

## Support

Pour toute question ou problème, veuillez :
1. Consulter la documentation
2. Vérifier les journaux
3. Ouvrir une issue sur GitHub

## Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.

## Contribution

Les contributions sont les bienvenues ! Pour contribuer :
1. Fork le projet
2. Créez une branche pour votre fonctionnalité
3. Committez vos changements
4. Push vers la branche
5. Ouvrez une Pull Request 
