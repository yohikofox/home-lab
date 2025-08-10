# Configuration Réseau - Migration

## Configuration Netgear R7100LG

### Paramètres Réseau de Base
```
IP Gateway: 10.0.0.1
Subnet Mask: 255.255.255.0 (/24)
DHCP Range: 10.0.0.2 - 10.0.0.200
DNS Primaire: 10.0.0.101 (PiHole)
DNS Secondaire: 1.1.1.1 (Cloudflare)
```

### Port Forwarding (NAT)
| Port Externe | IP Interne | Port Interne | Service |
|--------------|------------|--------------|---------|
| 80 | 10.0.0.101 | 80 | HTTP → Nginx Proxy Manager |
| 443 | 10.0.0.101 | 443 | HTTPS → Nginx Proxy Manager |

### Configuration WiFi
```
SSID: [À_DÉFINIR]
Sécurité: WPA3 (ou WPA2 si incompatible)
Mot de passe: [À_DÉFINIR]
Canal: Auto (ou canal fixe si interférences)
Bande: 2.4GHz + 5GHz
```

## Configuration Machines

### PC Lenovo - Docker Host
```
Interface: Ethernet
IP: 10.0.0.101 (fixe)
Netmask: 255.255.255.0
Gateway: 10.0.0.1
DNS: 127.0.0.1 (PiHole local), 10.0.0.1 (backup)
```

**Services impactés:**
- Nginx Proxy Manager (port forwarding)
- PiHole (DNS du réseau)
- Tous les services Docker (pas d'impact direct)

### Raspberry Pi 4 - Home Assistant
```
Interface: WiFi
SSID: [SSID_NETGEAR]
IP: 10.0.0.100 (fixe ou réservation DHCP)
Netmask: 255.255.255.0
Gateway: 10.0.0.1
DNS: 10.0.0.101 (PiHole), 1.1.1.1 (backup)
```

**Services impactés:**
- Home Assistant Core
- Zigbee2MQTT
- Frigate
- Mosquitto MQTT

## Mapping des Domaines Locaux

### Configuration PiHole (DNS Local)
| Domaine | IP de Destination | Service |
|---------|------------------|---------|
| vault.homelab.local | 10.0.0.101 | Vaultwarden |
| auth.homelab.local | 10.0.0.101 | Zitadel |
| assets.homelab.local | 10.0.0.101 | Snipe-IT |
| print.homelab.local | 10.0.0.101 | OctoPrint |
| pi.homelab.local | 10.0.0.101 | PiHole Admin |
| homeassistant.local | 10.0.0.100 | Home Assistant |

## Comparaison Avant/Après

### Avant Migration (Huawei)
```
Réseau: 192.168.1.0/24
Routeur: Huawei (192.168.1.1)
PC Lenovo: 192.168.1.101
RPI 4: WiFi Freebox (réseau séparé)
DNS: PiHole sur 192.168.1.101
Port Forwarding: 80/443 → 192.168.1.101
```

### Après Migration (Netgear)
```
Réseau: 10.0.0.0/24
Routeur: Netgear R7100LG (10.0.0.1)
PC Lenovo: 10.0.0.101
RPI 4: WiFi Netgear (10.0.0.100)
DNS: PiHole sur 10.0.0.101
Port Forwarding: 80/443 → 10.0.0.101
```

## Configuration Réseau Linux

### PC Lenovo (Ubuntu/Debian)
```bash
# /etc/netplan/01-network-manager-all.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    [INTERFACE_NAME]:
      dhcp4: no
      addresses:
        - 10.0.0.101/24
      gateway4: 10.0.0.1
      nameservers:
        addresses: [127.0.0.1, 10.0.0.1]
```

### Raspberry Pi (Raspberry Pi OS)
```bash
# /etc/dhcpcd.conf
interface wlan0
static ip_address=10.0.0.100/24
static routers=10.0.0.1
static domain_name_servers=10.0.0.101 1.1.1.1

# /etc/wpa_supplicant/wpa_supplicant.conf
network={
    ssid="[SSID_NETGEAR]"
    psk="[WIFI_PASSWORD]"
}
```

## Services Docker - Vérifications

### Nginx Proxy Manager
- Port forwarding externe: ✅ (80/443 → 10.0.0.101)
- Réseau Docker interne: ✅ (pas d'impact)

### PiHole
- Configuration DNS routeur: ⚠️ (changer pour 10.0.0.101)
- Interface d'écoute: ✅ (0.0.0.0:53)

### Autres Services
- Vaultwarden: ✅ (réseau Docker interne)
- Zitadel: ✅ (réseau Docker interne)
- Home Assistant: ⚠️ (vérifier intégrations avec IPs)

## Tests de Validation

### Connectivité de Base
```bash
# Depuis PC Lenovo
ping 10.0.0.1        # Routeur
ping 10.0.0.100      # RPI
ping 8.8.8.8         # Internet
nslookup google.com  # DNS

# Depuis RPI
ping 10.0.0.1        # Routeur
ping 10.0.0.101      # PC Lenovo
ping 8.8.8.8         # Internet
```

### Services Web
```bash
curl -I https://vault.example.local
curl -I http://10.0.0.100:8123  # Home Assistant
curl -I http://10.0.0.101:81    # NPM Admin
```

### DNS Local
```bash
nslookup vault.homelab.local 10.0.0.101
nslookup homeassistant.local 10.0.0.101
```