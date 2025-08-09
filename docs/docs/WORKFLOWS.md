---
sidebar_position: 8
---

# Documentation des Workflows N8N

## Vue d'ensemble

Ce document détaille les workflows N8N créés pour automatiser la disaster recovery de Vaultwarden.

## Workflows disponibles

### 1. Sauvegarde quotidienne (`daily_backup_workflow.json`)

**Objectif** : Effectuer une sauvegarde automatique tous les jours à 2h du matin.

**Déclencheur** : Cron `0 2 * * *` (2h00 chaque jour)

**Étapes** :
1. **Schedule Daily Backup** - Déclencheur cron quotidien
2. **Execute Backup Script** - Exécution du script de sauvegarde
3. **Check Backup Success** - Vérification du succès via JSON de retour
4. **Upload to Google Drive** - Upload de la sauvegarde SQLite (si succès)
5. **Send Success Notification** - Notification Telegram de succès
6. **Send Failure Notification** - Notification Telegram d'échec
7. **Cleanup Old Backups** - Suppression des sauvegardes > 30 jours

**Variables d'environnement utilisées** :
- `TELEGRAM_CHAT_ID`
- `BACKUP_RETENTION_DAYS`

**Outputs esperés** :
- Fichier SQLite dans `/backups/vaultwarden/daily/`
- Archive tar.gz complète
- Notification Telegram avec tailles des fichiers
- Upload Google Drive de la sauvegarde SQLite

### 2. Monitoring de santé (`health_monitoring_workflow.json`)

**Objectif** : Surveiller Vaultwarden toutes les 15 minutes et réagir aux pannes.

**Déclencheur** : Cron `*/15 * * * *` (toutes les 15 minutes)

**Étapes** :
1. **Schedule Health Check** - Déclencheur cron 15min
2. **Execute Health Check** - Script de vérification santé
3. **Check Health Status** - Test si statut = "healthy"
4. **Is Service Down** - Test si statut = "down"
5. **Restart Container** - Redémarrage automatique Docker
6. **Send Critical Alert** - Alerte critique (service down)
7. **Send Warning Alert** - Alerte warning (dégradé)
8. **Wait Before Recheck** - Attente 30s après redémarrage
9. **Recheck After Restart** - Nouvelle vérification santé
10. **Check Recovery** - Test si récupération OK
11. **Send Recovery Notification** - Notification de récupération
12. **Send Recovery Failure** - Notification d'échec récupération

**Statuts gérés** :
- `healthy` : Aucune action
- `degraded` : Notification warning
- `down` : Redémarrage + alerte critique
- `critical` : Alerte critique

**Logique de redémarrage** :
1. Détection service down
2. Tentative redémarrage Docker
3. Attente 30 secondes
4. Nouvelle vérification
5. Notification du résultat

### 3. Test de restauration mensuel (`monthly_test_restore_workflow.json`)

**Objectif** : Valider l'intégrité des sauvegardes le 1er de chaque mois.

**Déclencheur** : Cron `0 3 1 * *` (3h00 le 1er du mois)

**Étapes** :
1. **Schedule Monthly Test** - Déclencheur mensuel
2. **Find Latest Backup** - Recherche de la dernière sauvegarde
3. **Check Backup Exists** - Vérification existence fichier
4. **Create Test Container** - Container temporaire Vaultwarden
5. **Test Backup Integrity** - Test structure SQLite
6. **Count Users in Backup** - Comptage utilisateurs
7. **Count Ciphers in Backup** - Comptage coffres/entrées
8. **Validate Data Exists** - Validation données > 0
9. **Send Success Report** - Rapport de succès détaillé
10. **Send Failure Report** - Rapport d'échec
11. **Send No Backup Alert** - Alerte aucune sauvegarde
12. **Cleanup Test Container** - Suppression container test

**Validations effectuées** :
- Existence du fichier de sauvegarde
- Intégrité de la structure SQLite
- Présence de données utilisateur
- Cohérence du nombre d'entrées

**Container de test** :
- Image : `vaultwarden/server:latest`
- Volume : Sauvegarde montée en lecture seule
- Nommage : `vaultwarden-test-YYYYMMDD`
- Suppression automatique après test

## Configuration des credentials

### Telegram Bot

Dans N8N, créez un credential "Telegram Bot" :
- **Name** : `Telegram Bot`
- **Access Token** : Token obtenu de @BotFather

### Google Drive

Dans N8N, créez un credential "Google Drive OAuth2 API" :
- **Grant Type** : Authorization Code
- **Client ID** : Depuis Google Cloud Console
- **Client Secret** : Depuis Google Cloud Console
- **Authorization URL** : `https://accounts.google.com/o/oauth2/v2/auth`
- **Access Token URL** : `https://oauth2.googleapis.com/token`
- **Scope** : `https://www.googleapis.com/auth/drive.file`

### SMTP/Email (optionnel)

Pour notifications email de secours :
- **Host** : `smtp-relay.brevo.com`
- **Port** : `587`
- **Security** : `STARTTLS`
- **Username/Password** : Depuis compte Brevo

## Personnalisation des workflows

### Modification des horaires

Éditez les expressions cron dans les nœuds "Schedule" :
- Quotidien : `0 2 * * *` (2h du matin)
- Monitoring : `*/15 * * * *` (toutes les 15min)
- Mensuel : `0 3 1 * *` (1er du mois à 3h)

### Ajout de stockages cloud

Pour ajouter AWS S3 ou autres :
1. Ajoutez le nœud correspondant après "Check Backup Success"
2. Configurez les credentials
3. Adaptez les notifications pour inclure le nouveau stockage

### Personnalisation des notifications

Modifiez les nœuds Telegram pour :
- Changer le format des messages
- Ajouter des emojis personnalisés
- Inclure des métriques supplémentaires
- Ajouter des liens vers monitoring

### Ajout de webhooks

Pour intégrer avec Slack, Discord, etc. :
1. Remplacez/complétez les nœuds Telegram
2. Configurez les webhooks appropriés
3. Adaptez le format des messages JSON

## Monitoring et logs

### Logs N8N

Les exécutions sont visibles dans l'interface N8N :
- Historique des exécutions
- Détails de chaque nœud
- Messages d'erreur détaillés
- Métriques de performance

### Logs des scripts

Scripts génèrent des logs dans `/backups/logs/` :
- `backup_YYYYMMDD_HHMMSS.log` : Logs de sauvegarde
- `healthcheck_YYYYMMDD.log` : Logs de monitoring

### Alertes par email

Configurez un nœud SMTP en cas d'échec critique :
```json
{
  "to": "admin@yolo.yt",
  "subject": "🚨 Alerte critique Vaultwarden",
  "body": "Détails de l'incident..."
}
```

## Résolution de problèmes

### Échecs de sauvegarde

**Causes fréquentes** :
- Permissions insuffisantes sur `/backups`
- Container Vaultwarden arrêté
- Espace disque insuffisant
- Problèmes réseau (upload cloud)

**Actions** :
1. Vérifier les logs du script
2. Tester manuellement : `./scripts/backup/vaultwarden_backup.sh daily`
3. Contrôler l'espace disque : `df -h`

### Échecs de monitoring

**Causes fréquentes** :
- URL incorrecte dans les variables d'env
- Certificats SSL expirés
- Firewall bloquant les requêtes

**Actions** :
1. Tester manuellement : `curl https://vault.yolo.yt/alive`
2. Vérifier les certificats SSL
3. Contrôler les logs Nginx Proxy Manager

### Échecs de test mensuel

**Causes fréquentes** :
- Sauvegardes corrompues
- Container Docker non fonctionnel
- Permissions sur les volumes

**Actions** :
1. Tester la sauvegarde manuellement avec SQLite
2. Vérifier l'intégrité : `sqlite3 backup.db .schema`
3. Contrôler les logs Docker

## Évolutions suggérées

### Court terme
- Ajouter monitoring espace disque
- Inclure métriques système dans rapports
- Rotation automatique des logs

### Moyen terme
- Tests de charge sur les restaurations
- Sauvegarde différentielle
- Intégration monitoring existant (Grafana, Prometheus)

### Long terme
- Réplication multi-sites
- Automatisation complète disaster recovery
- Tests de basculement automatiques
