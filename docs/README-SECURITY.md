# 🔒 Sécurité et Configuration

Ce document explique comment configurer en toute sécurité votre home lab en personnalisant les paramètres selon votre environnement.

## ⚠️ Important - Sécurité

**Ce repository est conçu pour être PUBLIC** et ne contient aucune information sensible. Toutes les références spécifiques ont été anonymisées :

- ✅ **Domaines** : `homelab.local` (exemple)
- ✅ **IPs** : Plages privées RFC1918
- ✅ **Hostnames** : `docker-host`, `homeassistant-pi` (génériques)
- ✅ **Credentials** : `[AUTO_GENERATED]` ou variables d'environnement

## 📁 Fichiers de Configuration

### 1. Variables d'environnement (`.env`)

```bash
# Copier le template
cp .env.example .env

# Éditer avec vos valeurs réelles
nano .env
```

**Exemple de personnalisation :**
```bash
# Remplacez par votre vrai domaine
HOMELAB_DOMAIN=votre-domaine.fr

# Vos IPs réelles
DOCKER_HOST_IP=192.168.1.150
HOMEASSISTANT_IP=192.168.1.151

# Vos hostnames
DOCKER_HOST_HOSTNAME=serveur-docker
HOMEASSISTANT_HOSTNAME=rpi-domotique
```

### 2. Configuration YAML (`config.yml`)

```bash
# Copier le template
cp config.yml.example config.yml

# Éditer avec vos paramètres
nano config.yml
```

## 🔧 Utilisation des Scripts

### Chargement automatique de la configuration

```bash
# Source du script de configuration
source scripts/load-config.sh

# Afficher la configuration chargée
source scripts/load-config.sh --show

# Générer les configurations depuis les templates
source scripts/load-config.sh --generate
```

### Variables automatiquement disponibles

Une fois la configuration chargée :

```bash
echo $HOMELAB_DOMAIN          # votre-domaine.fr
echo $VAULTWARDEN_DOMAIN      # vault.votre-domaine.fr  
echo $DOCKER_HOST_IP          # 192.168.1.150
echo $SSL_EMAIL              # admin@votre-domaine.fr
```

## 🛡️ Bonnes Pratiques

### 1. Fichiers à ne jamais committer

Ajoutez dans votre `.gitignore` :

```gitignore
# Configuration personnelle
.env
config.yml
generated/

# Secrets et certificats
secrets/
*.key
*.pem
*.p12

# Logs
*.log
logs/

# Backups contenant des données sensibles
backups/
*.sql
*.dump
```

### 2. Gestion des secrets

Les credentials sont gérés de plusieurs façons :

1. **Auto-génération** : Le script génère des mots de passe sécurisés
2. **Variables d'environnement** : Stockage dans `.env` (non committé)
3. **Fichiers secrets** : Stockage chiffré dans `~/.homelab/secrets/`

### 3. Validation de la configuration

Avant déploiement :

```bash
# Vérifier la configuration
./scripts/validate-config.sh

# Test de connectivité
./scripts/test-network.sh

# Audit de sécurité
./scripts/security-audit.sh
```

## 📋 Templates Disponibles

Le système de templates permet de générer automatiquement :

- **docker-compose.yml** avec vos domaines
- **nginx.conf** avec vos certificats SSL
- **pihole.conf** avec vos DNS
- **monitoring.yml** avec vos alertes

### Exemple de template

```yaml
# templates/docker-compose.template
version: '3.8'
services:
  vaultwarden:
    image: vaultwarden/server
    environment:
      DOMAIN: https://${VAULTWARDEN_DOMAIN}
      ADMIN_TOKEN: ${VAULTWARDEN_ADMIN_TOKEN}
    labels:
      traefik.http.routers.vault.rule: Host(`${VAULTWARDEN_DOMAIN}`)
```

Généré automatiquement en :

```yaml
# generated/docker-compose.yml
version: '3.8'
services:
  vaultwarden:
    image: vaultwarden/server
    environment:
      DOMAIN: https://vault.votre-domaine.fr
      ADMIN_TOKEN: [généré automatiquement]
    labels:
      traefik.http.routers.vault.rule: Host(`vault.votre-domaine.fr`)
```

## 🔍 Vérifications de Sécurité

### Audit automatique

```bash
# Vérifier qu'aucun secret n'est exposé
./scripts/security-scan.sh

# Audit des permissions
./scripts/check-permissions.sh

# Test de pénétration basique
./scripts/basic-pentest.sh
```

### Points de contrôle

- [ ] Fichier `.env` dans `.gitignore`
- [ ] Pas de credentials en dur dans le code
- [ ] Certificats SSL configurés
- [ ] Firewall configuré (fail2ban, ufw)
- [ ] SSH sécurisé (clés seulement)
- [ ] Backups chiffrés

## 🚀 Déploiement Sécurisé

1. **Préparation**
   ```bash
   git clone https://github.com/YOUR_USERNAME/home-lab.git
   cd home-lab
   cp .env.example .env
   cp config.yml.example config.yml
   ```

2. **Configuration**
   ```bash
   # Éditer avec vos vraies valeurs
   nano .env
   nano config.yml
   ```

3. **Validation**
   ```bash
   source scripts/load-config.sh --show
   ./scripts/validate-config.sh
   ```

4. **Déploiement**
   ```bash
   ./bootstrap/deploy.sh --config config.yml
   ```

## ❓ FAQ Sécurité

**Q: Puis-je forker ce repository public ?**  
R: Oui ! Il est conçu pour être fork-friendly. Vos secrets restent dans `.env` (non committé).

**Q: Comment changer de domaine ?**  
R: Modifiez `HOMELAB_DOMAIN` dans `.env`, relancez `load-config.sh --generate`.

**Q: Les certificats SSL sont-ils automatiques ?**  
R: Oui, Let's Encrypt via Nginx Proxy Manager avec votre domaine réel.

**Q: Comment migrer vers un nouveau domaine ?**  
R: Utilisez le script `scripts/migrate-domain.sh` pour une migration propre.

---

🔒 **Sécurité avant tout** : Ce système permet d'avoir un repository public ET sécurisé !