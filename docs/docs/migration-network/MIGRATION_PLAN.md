# Plan de Migration Réseau - Suppression Huawei

## Objectif
Remplacer complètement le router Huawei par le Netgear R7100LG comme routeur principal.

## Architecture Actuelle vs Cible

### Actuelle
```mermaid
graph LR
    Internet["🌐 Internet"]
    Freebox["📡 Freebox Ultra<br/>(Salon)<br/>192.168.0.x"]
    CPL["⚡ CPL"]
    Switch["🔀 Switch<br/>(Bureau)"]
    Huawei["🔴 Huawei Router<br/>(Bureau)<br/>192.168.1.x<br/>PRINCIPAL"]
    NetgearOld["⚪ Netgear R7100LG<br/>(Isolé/Inutilisé)"]
    Lenovo["💻 PC Lenovo<br/>(Bureau)<br/>192.168.1.101"]
    RPI["🍓 RPI 4<br/>(WiFi Freebox)<br/>192.168.0.x"]
    
    Internet --> Freebox
    Freebox --> CPL
    CPL --> Switch
    Switch --> Huawei
    Switch -.-> NetgearOld
    Huawei --> Lenovo
    Freebox -.->|WiFi| RPI
    
    classDef current fill:#ffcccc,stroke:#ff0000,stroke-width:2px,color:#000
    classDef unused fill:#f0f0f0,stroke:#666,stroke-dasharray: 5 5,color:#333
    classDef freebox fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    
    class Huawei,Lenovo current
    class NetgearOld unused
    class Freebox,CPL,Switch freebox
```

### Cible - Architecture Double NAT
```mermaid
graph LR
    Internet["🌐 Internet"]
    Freebox["📡 Freebox Ultra<br/>(Salon)<br/>192.168.0.x<br/>Niveau 1 NAT"]
    Netgear["🟢 Netgear R7100LG<br/>(Salon)<br/>10.0.0.x<br/>Niveau 2 NAT"]
    CPL["⚡ CPL<br/>(Salon ↔ Bureau)"]
    Switch["🔀 Switch<br/>(Bureau)"]
    Lenovo["💻 PC Lenovo<br/>(Bureau)<br/>10.0.0.101"]
    RPI["🍓 RPI 4<br/>(WiFi Netgear)<br/>10.0.0.100"]
    Devices["📱 Autres appareils<br/>(WiFi Netgear)<br/>10.0.0.x"]
    
    Internet --> Freebox
    Freebox -->|Ethernet| Netgear
    Netgear --> CPL
    CPL --> Switch
    Switch --> Lenovo
    Netgear -.->|WiFi| RPI
    Netgear -.->|WiFi| Devices
    
    classDef target fill:#ccffcc,stroke:#00aa00,stroke-width:2px,color:#000
    classDef nat1 fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    classDef nat2 fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    classDef transport fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#000
    
    class Lenovo,RPI,Devices target
    class Freebox nat1
    class Netgear nat2
    class CPL,Switch transport
```

### Double NAT - Flux de données
```mermaid
graph TB
    subgraph "Niveau 1 - Freebox (192.168.0.x)"
        Freebox_WAN["WAN: Internet"]
        Freebox_LAN["LAN: 192.168.0.1"]
        Netgear_WAN["Netgear WAN<br/>192.168.0.xxx"]
    end
    
    subgraph "Niveau 2 - Netgear (10.0.0.x)"
        Netgear_LAN["LAN: 10.0.0.1"]
        CPL_Port["Port CPL"]
        WiFi_Port["WiFi"]
    end
    
    subgraph "Réseau Local (10.0.0.x)"
        Lenovo_IP["💻 Lenovo<br/>10.0.0.101"]
        RPI_IP["🍓 RPI<br/>10.0.0.100"]
        Other_IP["📱 Autres<br/>10.0.0.x"]
    end
    
    Freebox_WAN --> Freebox_LAN
    Freebox_LAN --> Netgear_WAN
    Netgear_WAN --> Netgear_LAN
    Netgear_LAN --> CPL_Port
    Netgear_LAN --> WiFi_Port
    CPL_Port --> Lenovo_IP
    WiFi_Port --> RPI_IP
    WiFi_Port --> Other_IP
    
    classDef nat1 fill:#e3f2fd,stroke:#1976d2,stroke-width:2px,color:#000
    classDef nat2 fill:#fff3e0,stroke:#f57c00,stroke-width:2px,color:#000
    classDef devices fill:#ccffcc,stroke:#00aa00,stroke-width:2px,color:#000
    
    class Freebox_WAN,Freebox_LAN,Netgear_WAN nat1
    class Netgear_LAN,CPL_Port,WiFi_Port nat2
    class Lenovo_IP,RPI_IP,Other_IP devices
```

## Changements Majeurs

### Réseau
- **Architecture**: Simple NAT → Double NAT (Freebox + Netgear)
- **Plage IP locale**: `192.168.1.x` → `10.0.0.x`
- **Routeur principal**: Huawei (bureau) → Netgear R7100LG (salon)
- **WiFi RPI**: Freebox WiFi → Netgear WiFi
- **Emplacement**: Netgear déplacé au salon (près Freebox)

### Services
- **Port forwarding double**: Internet → Freebox → Netgear → `10.0.0.101`
- **DNS PiHole**: `10.0.0.101` (nouvelle IP Lenovo)
- **Domaines locaux**: Tous pointent vers `10.0.0.101`
- **CPL**: Transport réseau `10.0.0.x` (bureau ↔ salon)

## Plan d'Exécution - Migration Double NAT

### Phase 1 - Installation Netgear (salon) - 0 downtime
1. **Installation physique Netgear**
   - Déplacement Netgear au salon
   - Connexion Ethernet: Freebox → Netgear (port WAN)
   - Alimentation Netgear

2. **Configuration Netgear R7100LG**
   - Connexion admin interface Netgear
   - Configuration WAN: DHCP (prendra IP Freebox 192.168.0.x)
   - Configuration LAN: 10.0.0.1/24
   - DHCP: 10.0.0.2-200
   - DNS: 10.0.0.101 (futur PiHole)
   - Configuration WiFi pour RPI

3. **Test connectivité Netgear**
   - Vérifier accès Internet depuis Netgear
   - Noter IP WAN attribuée par Freebox
   - Test WiFi fonctionnel

### Phase 2 - Migration réseau (downtime ~15-30min)
1. **Sauvegarde configuration actuelle**
   - Export config Huawei
   - Backup IPs et services
   - Exécution script pre-migration.sh

2. **Basculement physique CPL**
   - Déconnexion CPL du switch (bureau)
   - Connexion CPL au port LAN Netgear (salon)

3. **Reconfiguration machines**
   - PC Lenovo: 192.168.1.101 → 10.0.0.101
   - RPI 4: WiFi Freebox → WiFi Netgear + 10.0.0.100

### Phase 3 - Configuration Double NAT
1. **Port forwarding Freebox**
   - 80 → IP_WAN_Netgear:80
   - 443 → IP_WAN_Netgear:443

2. **Port forwarding Netgear**
   - 80 → 10.0.0.101:80 (PC Lenovo)
   - 443 → 10.0.0.101:443 (PC Lenovo)

3. **Tests services web**
   - Vérification accès externe
   - Tests domaines locaux

### Phase 4 - Validation et finalisation
1. **Exécution script validation**
   - Tests connectivité complète
   - Validation services Docker
   - Tests Home Assistant

2. **Retrait définitif Huawei**
   - Déconnexion physique
   - Nettoyage switch bureau
   - Stockage Huawei

3. **Documentation finale**
   - Mise à jour configurations
   - Backup nouvelle architecture

## Points d'Attention

### Risques Identifiés
- **Double NAT**: Peut compliquer certains services (P2P, gaming)
- **Port forwarding double**: Configuration plus complexe
- **CPL performance**: Transport réseau sur plus longue distance
- **WiFi RPI**: Double changement (réseau + IP)
- **Services Docker**: Vérifier aucune IP hardcodée

### Plans de Rollback
- **Rollback physique rapide**: Remettre CPL sur switch + Huawei
- **Sauvegarde complète** avant migration
- **Config Netgear**: Garde la configuration en cas de retour arrière
- **Scripts automatisés** de rollback

### Avantages Architecture Double NAT
✅ **Sécurité**: Isolation réseau local vs Freebox
✅ **Contrôle total**: Netgear gère le réseau local
✅ **Migration progressive**: Installation sans coupure
✅ **Administration centralisée**: Salon (Freebox + Netgear)

## Timeline Estimée
- **Phase 1 (Installation Netgear)**: 1-2h
- **Phase 2 (Migration)**: 30min downtime
- **Phase 3 (Double NAT)**: 30min
- **Phase 4 (Validation)**: 1h
- **Total**: ~4h avec rollback possible

## Validation Success Criteria
- [ ] Internet accessible depuis PC Lenovo et RPI
- [ ] Services web accessibles via `vault.example.local`
- [ ] Home Assistant fonctionnel
- [ ] DNS PiHole résout correctement
- [ ] Communication HA ↔ services Docker
- [ ] Performance réseau acceptable