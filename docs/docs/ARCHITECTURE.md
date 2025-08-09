---
sidebar_position: 2
---

# Architecture du Home Lab Yohikofox

## Vue d'ensemble

Le home lab Yohikofox est structuré autour de 4 composants principaux répartis selon leur fonction et leurs capacités matérielles. L'architecture privilégie la séparation des préoccupations avec la domotique isolée sur le Raspberry Pi et les services applicatifs sur le PC Lenovo.

## Schéma d'architecture

```mermaid
graph TB
    Internet["🌐 Internet"]
    Router["📡 Routeur Netgear R7100LG<br/>• Point d'entrée réseau<br/>• Routage & NAT<br/>• WiFi domestique"]
    
    subgraph HomeNetwork["🏠 Réseau Local"]
        RPI["🍓 RPI 4 - 8GB RAM<br/>🏠 DOMOTIQUE"]
        Lenovo["💻 PC Lenovo - 16GB RAM, 4 vCPU<br/>🐳 SERVICES DOCKER"]
        
        subgraph DockerServices["Services Docker"]
            Management["⚙️ Gestion & Monitoring<br/>• Portainer<br/>• Netdata"]
            Apps["🛠️ Services Applicatifs<br/>• Vaultwarden<br/>• Zitadel<br/>• Snipe-IT"]
        end
        
        subgraph IoTDevices["🏠 Périphériques IoT"]
            Zigbee["📡 Zigbee/Z-Wave"]
            Cameras["📹 Caméras"]
        end
    end
    
    Internet --> Router
    Router --> RPI
    Router --> Lenovo
    Lenovo --> Management
    Lenovo --> Apps
    RPI --> IoTDevices
    IoTDevices --> Zigbee
    IoTDevices --> Cameras
    
    classDef internet fill:#e1f5fe,stroke:#0277bd,stroke-width:2px,color:#000
    classDef router fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    classDef homeAssistant fill:#e8f5e8,stroke:#388e3c,stroke-width:2px,color:#000
    classDef docker fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    classDef iot fill:#fce4ec,stroke:#c2185b,stroke-width:2px,color:#000
    
    class Internet internet
    class Router router
    class RPI,IoTDevices,Zigbee,Cameras homeAssistant
    class Lenovo,DockerServices,Management,Apps docker
```

## Infrastructure matérielle

### Routeur Principal
**Netgear R7100LG**
- **Rôle** : Passerelle Internet et routeur principal
- **Fonctions** :
  - Routage et NAT vers Internet
  - Réseau WiFi domestique
  - DHCP (probablement)
  - Port forwarding vers services internes

### Serveur Principal - PC Lenovo
**Spécifications** :
- **RAM** : 16 GB
- **CPU** : 4 vCPU
- **OS** : Linux (présumé)
- **Rôle** : Serveur d'applications containerisées

**Capacités** :
- Hébergement des services Docker
- Gestion de l'infrastructure applicative
- Services réseau avancés
- Stockage et sauvegarde

### Serveur Domotique - Raspberry Pi 4
**Spécifications** :
- **RAM** : 8 GB
- **OS** : Home Assistant Operating System
- **Rôle** : Hub domotique central

**Capacités** :
- Gestion des périphériques IoT
- Protocoles domotique (Zigbee, Z-Wave)
- Traitement vidéo (Frigate)
- Automatisations domestiques

### Clients
- **Laptops** : Accès admin et utilisation quotidienne
- **Tablets** : Interfaces domotique et monitoring
- **Smartphones** : Applications mobiles et notifications

## Répartition des services

### PC Lenovo - Stack Docker

#### Gestion & Infrastructure
| Service                 | Port   | Description                   | Usage                         |
|-------------------------|--------|-------------------------------|-------------------------------|
| **Portainer**           | 9000   | Interface de gestion Docker   | Administration containers     |
| **Netdata**             | 19999  | Monitoring système temps réel | Surveillance performance      |
| **Nginx Proxy Manager** | 80/443 | Reverse proxy + SSL           | Exposition sécurisée services |

#### Services Applicatifs
| Service         | Domaine        | Description                   | Usage                        |
|-----------------|----------------|-------------------------------|------------------------------|
| **Vaultwarden** | vault.yolo.yt  | Gestionnaire de mots de passe | Coffre-fort personnel        |
| **Zitadel**     | auth.yolo.yt   | Gestionnaire d'identité/SSO   | Authentification centralisée |
| **Snipe-IT**    | assets.yolo.yt | Gestion d'inventaire IT       | Suivi équipements            |
| **OctoPrint**   | print.yolo.yt  | Gestion imprimante 3D         | Impression 3D à distance     |

#### Services Réseau
| Service    | Domaine    | Description       | Usage           |
|------------|------------|-------------------|-----------------|
| **PiHole** | pi.yolo.yt | DNS + Blocage pub | Filtrage réseau |

### Raspberry Pi 4 - Home Assistant OS

#### Core Domotique
| Service            | Description                 | Usage                        |
|--------------------|-----------------------------|------------------------------|
| **Home Assistant** | Hub domotique principal     | Automatisations et interface |
| **Zigbee2MQTT**    | Passerelle protocole Zigbee | Capteurs et actionneurs      |
| **Frigate**        | Analyse vidéo IA            | Surveillance et détection    |

#### Add-ons Home Assistant
- **File Editor** : Édition configuration
- **Terminal & SSH** : Accès shell distant  
- **Mosquitto MQTT** : Broker messages IoT
- **Node-RED** : Automatisations avancées (si installé)
- **InfluxDB + Grafana** : Métriques historiques (si installé)

## Architecture réseau

### Segmentation logique

```mermaid
graph LR
    Internet["🌐 Internet"]
    Router["📡 Routeur<br/>NAT"]
    Network["🏠 Réseau Local<br/>192.168.1.0/24"]
    
    subgraph Devices["Périphériques"]
        RPI["🍓 RPI Domotique<br/>📍 192.168.1.100<br/>🔌 Port: 8123"]
        Lenovo["💻 PC Lenovo Services<br/>📍 192.168.1.101<br/>🔌 Ports: 80,443,9000..."]
    end
    
    Internet --> Router
    Router --> Network
    Network --> RPI
    Network --> Lenovo
    
    classDef network fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    classDef device fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    
    class Network network
    class RPI,Lenovo device
```

### Flux de données principaux

1. **Internet → Services** : Via Nginx Proxy Manager
2. **Clients → Home Assistant** : Interface domotique (port 8123)  
3. **Capteurs → MQTT → HA** : Données IoT via Zigbee2MQTT
4. **Caméras → Frigate → HA** : Flux vidéo et détections
5. **Services Docker ↔ PiHole** : Résolution DNS filtrée

### Domaines et certificats

**Configuration DNS** :
- **PiHole** : Résolution locale + blocage publicitaire
- **Nginx Proxy Manager** : Reverse proxy avec SSL Let's Encrypt
- **Domaine principal** : `yolo.yt`

**Sous-domaines exposés** :
- `vault.yolo.yt` → Vaultwarden
- `auth.yolo.yt` → Zitadel  
- `assets.yolo.yt` → Snipe-IT
- `print.yolo.yt` → OctoPrint
- `pi.yolo.yt` → PiHole admin

## Sécurité et accès

### Authentification
- **Zitadel** : SSO centralisé pour services compatibles
- **Nginx Proxy Manager** : Terminaison SSL et protection
- **Home Assistant** : Authentification locale + API tokens

### Réseau
- **Firewall** : Au niveau routeur (NAT + règles)
- **SSL/TLS** : Certificats Let's Encrypt via NPM
- **VPN** : Accès distant sécurisé (à confirmer)

### Sauvegardes
- **Vaultwarden** : Sauvegarde SQLite (via N8N prévu)
- **Home Assistant** : Snapshots automatiques
- **Configurations** : Git pour Infrastructure as Code

## Points forts de l'architecture

✅ **Séparation des préoccupations** : Domotique isolée du reste  
✅ **Haute disponibilité** : Services critiques répartis  
✅ **Sécurité** : SSL partout + authentification centralisée  
✅ **Monitoring** : Netdata + possibles métriques HA  
✅ **Évolutivité** : Containerisation Docker facilitant les mises à jour  

## Points d'amélioration potentiels

🔄 **Sauvegarde centralisée** : Stratégie globale (en cours avec N8N)  
🔄 **Monitoring unifié** : Dashboard global des services  
🔄 **Réplication** : Services critiques sur les deux machines  
🔄 **Réseau avancé** : VLANs pour isolation renforcée  

## Dépendances critiques

### Services interdépendants
- **Nginx Proxy Manager** ← Tous les services web
- **PiHole** ← Résolution DNS pour domaines locaux
- **Zitadel** ← Services utilisant le SSO
- **Home Assistant** ← Tous les périphériques domotique

### Points de défaillance unique
- **Routeur** : Panne = perte Internet et réseau local
- **PC Lenovo** : Panne = perte services applicatifs
- **RPI** : Panne = perte domotique complète

Cette architecture offre un excellent équilibre entre fonctionnalités, performance et maintenabilité pour un home lab personnel.
