---
sidebar_position: 6
---

# Installation Rapide - Home Lab

## Installation en une commande

### Option 1: Installation directe depuis GitHub
```bash
curl -sSL https://raw.githubusercontent.com/yohikofox/home-lab/main/install.sh | bash
```

### Option 2: Installation locale
```bash
git clone https://github.com/yohikofox/home-lab.git
cd home-lab
./install.sh
```

## Systèmes supportés

### ✅ Linux (Automatique)
- **Ubuntu** / Debian / Raspbian
- **CentOS** / RHEL / Fedora / AlmaLinux / Rocky
- **Arch Linux** / Manjaro

### ✅ macOS (Automatique)
- Intel et Apple Silicon (M1/M2)
- Homebrew installé automatiquement

### ⚠️ Windows
- Utilisez **WSL2** avec une distribution Linux supportée
- Ou Docker Desktop + installation manuelle

## Prérequis automatiquement installés

Le script détecte et installe automatiquement :
- **Docker** + **Docker Compose**
- **Git**, **curl**, **wget**, **openssl**
- **Homebrew** (sur macOS)

## Ce qui est installé

### Services Docker
- **N8N** : Interface d'automatisation sur port 5678
- **Redis** : Cache pour N8N

### Scripts d'automatisation
- Sauvegarde Vaultwarden
- Health check services
- Installation et configuration

### Workflows N8N prêts à l'emploi
- Sauvegarde quotidienne (2h00)
- Monitoring continu (15min)  
- Test restauration mensuel

### Configuration sécurisée
- Mot de passe N8N généré automatiquement
- Fichier `.env` avec permissions restreintes
- Aucun secret exposé dans le code

## Après l'installation

### 1. Accès N8N
```
URL: http://localhost:5678
Utilisateur: admin
Mot de passe: [affiché à la fin de l'installation]
```

### 2. Configuration des tokens
Éditez le fichier `.env` généré :
```bash
nano ~/home-lab/docker-compose/n8n/.env
```

Configurez au minimum :
- `TELEGRAM_BOT_TOKEN` : Créez un bot via @BotFather
- `TELEGRAM_CHAT_ID` : Votre ID de chat Telegram

### 3. Import des workflows
1. Connectez-vous à N8N
2. Importez les workflows depuis `~/home-lab/workflows/`
3. Configurez vos credentials (Telegram, Google Drive)
4. Activez les workflows

### 4. Test des scripts
```bash
cd ~/home-lab
./scripts/backup/vaultwarden_backup.sh daily
./scripts/monitoring/health_check.sh
```

## Gestion des services

### Commandes utiles
```bash
cd ~/home-lab/docker-compose/n8n

# Démarrer les services
docker compose up -d

# Arrêter les services  
docker compose down

# Voir les logs
docker compose logs -f n8n

# Redémarrer
docker compose restart
```

### Localisation des fichiers
- **Installation** : `~/home-lab/`
- **Configuration** : `~/home-lab/docker-compose/n8n/.env`
- **Sauvegardes** : `~/home-lab/backups/`
- **Logs** : `~/home-lab/backups/logs/`

## Résolution de problèmes

### N8N ne démarre pas
```bash
# Vérifier les logs
docker compose -f ~/home-lab/docker-compose/n8n/docker-compose.yml logs n8n

# Vérifier les ports
netstat -tulpn | grep 5678

# Redémarrer les services
docker compose -f ~/home-lab/docker-compose/n8n/docker-compose.yml restart
```

### Permissions Docker
Si vous obtenez des erreurs de permissions Docker :
```bash
# Ajouter votre utilisateur au groupe docker
sudo usermod -aG docker $USER

# Redémarrer votre session (logout/login)
# ou utiliser newgrp temporairement
newgrp docker
```

### Script d'installation échoue
1. Vérifiez votre connexion Internet
2. Assurez-vous d'avoir les droits sudo
3. Ne lancez PAS le script en tant que root
4. Sur Ubuntu/Debian : `sudo apt update` avant installation

## Désinstallation

### Arrêter et supprimer les services
```bash
cd ~/home-lab/docker-compose/n8n
docker compose down -v  # -v supprime les volumes

# Supprimer les images Docker (optionnel)
docker rmi n8nio/n8n:latest redis:7-alpine
```

### Supprimer les fichiers
```bash
rm -rf ~/home-lab
```

## Sécurité

### Bonnes pratiques
- ✅ Mot de passe N8N généré automatiquement  
- ✅ Fichier `.env` avec permissions 600
- ✅ Aucun secret dans le repository
- ✅ Variables d'environnement pour configuration

### Exposition réseau
Par défaut, N8N n'est accessible que localement (localhost:5678).

Pour exposer via Nginx Proxy Manager :
1. Configurez un proxy host vers `n8n:5678`
2. Activez SSL avec Let's Encrypt
3. Ajustez les variables d'environnement N8N

## Support

### Documentation complète
- [Architecture](ARCHITECTURE.md) - Vue d'ensemble système
- [Services](SERVICES.md) - Inventaire détaillé
- [Workflows](WORKFLOWS.md) - Configuration N8N
- [Réseau](NETWORK.md) - Topologie et sécurité

### Logs de débogage
```bash
# Logs système d'installation
journalctl -u docker

# Logs N8N en temps réel
docker compose -f ~/home-lab/docker-compose/n8n/docker-compose.yml logs -f

# Logs des scripts personnalisés
tail -f ~/home-lab/backups/logs/*.log
```

---

**Installation testée sur** : Ubuntu 22.04, Debian 12, CentOS 9, Fedora 38, Arch Linux, macOS 13+ (Intel/M1/M2)
