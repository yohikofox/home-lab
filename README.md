# Yohikofox Home Lab

Infrastructure as Code et automatisations pour home lab personnel avec focus sur la disaster recovery et le monitoring.

## Projets actuels

### N8N Disaster Recovery pour Vaultwarden

Solution complète d'automatisation de la disaster recovery pour Vaultwarden avec N8N.

**Fonctionnalités** :
- ✅ Sauvegarde quotidienne automatique (SQLite + données complètes)
- ✅ Monitoring continu avec redémarrage automatique
- ✅ Test de restauration mensuel
- ✅ Notifications Telegram en temps réel
- ✅ Upload cloud automatique (Google Drive)
- ✅ Nettoyage automatique des anciennes sauvegardes

**Infrastructure** :
- Serveur local avec Docker + Docker Compose
- Nginx Proxy Manager pour reverse proxy
- PiHole pour DNS local
- Domaine principal : `yolo.yt`

## Structure du projet

```
home-lab/
├── docker-compose/
│   └── n8n/                    # Configuration N8N
├── scripts/
│   ├── backup/                 # Scripts de sauvegarde
│   ├── monitoring/             # Scripts de monitoring
│   └── install_n8n.sh         # Installation automatique
├── workflows/                  # Workflows N8N (JSON)
├── docs/                       # Documentation détaillée
└── config/                     # Configurations diverses
```

## Installation rapide

```bash
# Cloner le projet
git clone https://github.com/Yohikofox/home-lab.git
cd home-lab

# Installation automatique N8N
./scripts/install_n8n.sh

# Configuration post-installation
nano docker-compose/n8n/.env
```

## Documentation

### Architecture et Infrastructure
- [🏗️ Architecture générale](docs/ARCHITECTURE.md) - Vue d'ensemble du home lab
- [🖥️ Inventaire des services](docs/SERVICES.md) - Détail de tous les services par machine
- [🌐 Architecture réseau](docs/NETWORK.md) - Topologie, DNS, sécurité réseau

### Projets spécifiques
- [📋 Guide d'installation N8N](docs/INSTALLATION.md) - Installation complète étape par étape
- [⚙️ Documentation workflows](docs/WORKFLOWS.md) - Détails techniques des automatisations
- [🎯 Contexte projet](CLAUDE.md) - Spécifications et objectifs détaillés

## Services déployés

| Service | URL | Description |
|---------|-----|-------------|
| Vaultwarden | `vault.yolo.yt` | Gestionnaire de mots de passe |
| N8N | `n8n.yolo.yt` | Automatisation workflows |
| Nginx Proxy Manager | `npm.yolo.yt` | Reverse proxy + SSL |
| PiHole | `pi.yolo.yt` | DNS + Ad-blocking |

## Workflows automatiques

1. **Sauvegarde quotidienne** (2h00) - Base SQLite + archive complète
2. **Monitoring continu** (15min) - Health check + auto-restart
3. **Test restauration** (mensuel) - Validation intégrité sauvegardes
4. **Nettoyage automatique** - Suppression anciennes sauvegardes

## Technologies utilisées

- **Containerisation** : Docker, Docker Compose
- **Automatisation** : N8N (workflows visuels)
- **Monitoring** : Scripts bash + health checks
- **Notifications** : Telegram Bot API
- **Stockage cloud** : Google Drive API
- **Reverse proxy** : Nginx Proxy Manager
- **DNS local** : PiHole

## Prochaines étapes

- [ ] Monitoring avancé avec métriques système
- [ ] Sauvegarde différentielle pour optimiser l'espace
- [ ] Tests de charge sur les restaurations
- [ ] Réplication multi-sites
- [ ] Intégration Grafana/Prometheus

## Support

Consultez la [documentation détaillée](docs/) ou les logs pour le dépannage :

```bash
# Logs N8N
docker-compose -f docker-compose/n8n/docker-compose.yml logs -f

# Logs sauvegardes
tail -f /backups/logs/backup_*.log

# Test manuel scripts
./scripts/backup/vaultwarden_backup.sh daily
./scripts/monitoring/health_check.sh
```