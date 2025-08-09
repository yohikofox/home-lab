---
sidebar_position: 1
---

# Home Lab Yohikofox

Bienvenue dans la documentation complète du **Home Lab Yohikofox** ! 🏠

Cette documentation couvre l'architecture complète, les services déployés, et les automatisations mises en place pour créer un environnement home lab robuste et moderne.

## Vue d'ensemble

Le home lab Yohikofox est structuré autour de 4 composants principaux :
- **Routeur Netgear R7100LG** - Point d'entrée réseau
- **PC Lenovo** (16GB RAM, 4 vCPU) - Services Docker applicatifs  
- **Raspberry Pi 4** (8GB) - Stack domotique avec Home Assistant
- **Clients** - Laptops, tablets, smartphones

## Installation rapide

### Installation en une commande 🚀
```bash
curl -sSL https://raw.githubusercontent.com/yohikofox/home-lab/main/install.sh | bash
```

**Systèmes supportés** : Linux (Ubuntu, Debian, CentOS, Fedora, Arch), macOS (Intel/M1/M2)

## Services principaux

| Service | Hébergement | Description |
|---------|-------------|-------------|
| **Vaultwarden** | PC Lenovo | Gestionnaire de mots de passe |
| **Home Assistant** | Raspberry Pi | Hub domotique central |
| **N8N** | PC Lenovo | Automatisation et workflows |
| **Nginx Proxy Manager** | PC Lenovo | Reverse proxy + SSL |
| **PiHole** | PC Lenovo | DNS + Blocage pub |

## Automatisations

- ✅ **Sauvegarde quotidienne** Vaultwarden (2h00)
- ✅ **Monitoring continu** services (15min)  
- ✅ **Test restauration** mensuel
- ✅ **Notifications Telegram** temps réel
- ✅ **Upload cloud** automatique

Explorez la documentation pour découvrir tous les détails techniques ! 📖
