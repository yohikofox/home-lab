# Installation N8N pour Disaster Recovery Vaultwarden

## Vue d'ensemble

Ce guide vous accompagne dans l'installation et la configuration de N8N pour automatiser la disaster recovery de votre instance Vaultwarden.

## Prérequis

- Docker et Docker Compose installés
- Instance Vaultwarden fonctionnelle
- Nginx Proxy Manager (recommandé)
- Accès SSH au serveur

## Installation automatique

### 1. Lancement de l'installation

```bash
cd /path/to/home-lab
./scripts/install_n8n.sh
```

Le script va automatiquement :
- Vérifier les prérequis
- Créer la structure de répertoires
- Générer la configuration
- Démarrer N8N
- Afficher les instructions finales

### 2. Configuration post-installation

Éditez le fichier `.env` généré :

```bash
nano docker-compose/n8n/.env
```

Configurez au minimum :
- `TELEGRAM_BOT_TOKEN` : Token de votre bot Telegram
- `TELEGRAM_CHAT_ID` : ID de votre chat Telegram
- Credentials Google Drive (optionnel)

## Configuration manuelle

### 1. Structure des répertoires

```bash
mkdir -p docker-compose/n8n
mkdir -p backups/vaultwarden/{daily,weekly,monthly,configs}
mkdir -p scripts/{backup,monitoring}
mkdir -p workflows
mkdir -p config
```

### 2. Configuration Docker Compose

Copiez le fichier `docker-compose/n8n/docker-compose.yml` et adaptez selon vos besoins.

Variables importantes :
- `N8N_USER` : Nom d'utilisateur admin
- `N8N_PASSWORD` : Mot de passe admin (généré automatiquement)
- Volumes montés pour accès Docker et données Vaultwarden

### 3. Scripts de sauvegarde

Les scripts dans `scripts/` sont prêts à l'emploi :
- `backup/vaultwarden_backup.sh` : Sauvegarde complète
- `monitoring/health_check.sh` : Vérification de santé

Rendez-les exécutables :
```bash
chmod +x scripts/*/*.sh
```

## Configuration des intégrations

### Telegram Bot

1. Créez un bot via @BotFather
2. Récupérez le token
3. Trouvez votre Chat ID (envoyez un message puis appelez l'API)
4. Configurez dans `.env`

### Google Drive (optionnel)

1. Créez un projet Google Cloud
2. Activez l'API Drive
3. Créez des credentials OAuth2
4. Configurez dans `.env`

### Nginx Proxy Manager

Ajoutez un proxy host :
- Domain: `n8n.yolo.yt`
- Forward Hostname: `n8n` (ou IP serveur)
- Forward Port: `5678`
- SSL: Activé

## Import des workflows

### Via interface N8N

1. Accédez à N8N : `http://n8n.yolo.yt` ou `http://localhost:5678`
2. Connectez-vous avec admin/mot_de_passe
3. Importez les workflows depuis `workflows/` :
   - `daily_backup_workflow.json`
   - `health_monitoring_workflow.json`
   - `monthly_test_restore_workflow.json`

### Configuration des credentials

Dans N8N, configurez :
1. **Telegram Bot** : Token et Chat ID
2. **Google Drive** : OAuth2 credentials
3. **SMTP** : Configuration email Brevo

## Vérification de l'installation

### Tests de base

```bash
# Vérifier les services
docker-compose ps

# Tester le script de backup
./scripts/backup/vaultwarden_backup.sh daily

# Tester le health check
./scripts/monitoring/health_check.sh

# Vérifier les logs N8N
docker-compose logs n8n
```

### Test des workflows

1. Exécutez manuellement chaque workflow dans N8N
2. Vérifiez les notifications Telegram
3. Contrôlez les sauvegardes générées

## Maintenance

### Logs

```bash
# Logs N8N
docker-compose -f docker-compose/n8n/docker-compose.yml logs -f n8n

# Logs des sauvegardes
ls -la /backups/logs/

# Logs système
journalctl -u docker -f
```

### Mise à jour

```bash
cd docker-compose/n8n
docker-compose pull
docker-compose up -d
```

### Sauvegarde de la configuration N8N

```bash
# Sauvegarder les workflows et credentials
docker exec n8n tar czf /tmp/n8n_backup.tar.gz -C /home/node/.n8n workflows.json credentials.json
docker cp n8n:/tmp/n8n_backup.tar.gz ./backups/n8n_config_$(date +%Y%m%d).tar.gz
```

## Dépannage

### N8N ne démarre pas

1. Vérifiez les logs : `docker-compose logs n8n`
2. Permissions des volumes : `sudo chown -R 1000:1000 /backups`
3. Port occupé : `netstat -tulpn | grep 5678`

### Workflows en échec

1. Vérifiez les credentials dans N8N
2. Testez les scripts manuellement
3. Contrôlez les permissions Docker socket

### Notifications non reçues

1. Validez le token Telegram
2. Vérifiez le Chat ID
3. Testez avec curl l'API Telegram

## Sécurité

### Recommandations

- N8N accessible uniquement via VPN ou IP whitelisting
- Mots de passe forts pour l'authentification
- Rotation régulière des tokens API
- Monitoring des accès aux logs

### Permissions Docker

N8N s'exécute en root pour accéder au socket Docker. Considérez :
- Utiliser Docker rootless
- Restreindre les commandes Docker disponibles
- Monitoring des actions Docker

## Support

Pour des problèmes ou questions :
1. Consultez les logs détaillés
2. Vérifiez la configuration des services externes
3. Testez les composants individuellement