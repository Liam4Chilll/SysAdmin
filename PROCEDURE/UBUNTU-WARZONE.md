# Configuration Ubuntu/Kali hybride

Cette documentation fournit une procédure professionnelle pour configurer un système Ubuntu ARM avec accès aux outils Kali Linux sans isolation.
La configuration garantit la stabilité du système tout en fournissant un accès à la demande aux outils de tests de pénétration.

## Prérequis

- Ubuntu 25 - ARM64
- droits admin
- Connexion Internet

## Procédure d'Installation

### 1-Configuration du Dépôt

Ajouter le dépôt Kali Linux avec une priorité basse pour maintenir la stabilité du système Ubuntu :

```bash
# Ajout du dépôt Kali Linux
echo 'deb https://http.kali.org/kali kali-rolling main non-free contrib' | sudo tee /etc/apt/sources.list.d/kali.list

# Ajout de la clé GPG Kali
wget -q -O - https://archive.kali.org/archive-key.asc | sudo apt-key add -

# Définition de la priorité basse pour les paquets Kali (Ubuntu reste prioritaire)
echo 'Package: *
Pin: release a=kali-rolling
Pin-Priority: 50' | sudo tee /etc/apt/preferences.d/kali.pref

# Mise à jour des listes de paquets
sudo apt update
```

### 2-Script d'Installation Intelligent

Créer un script d'installation intelligent qui priorise les paquets Ubuntu :

```bash
# Création du répertoire de scripts
mkdir -p ~/bin

# Création du script d'installation intelligent
cat > ~/bin/kali-install << 'EOF'
#!/bin/bash
TOOL=$1

if [ -z "$TOOL" ]; then
    echo "Usage: kali-install <nom-outil>"
    exit 1
fi

# Vérification de la disponibilité Ubuntu en premier
if apt-cache show $TOOL 2>/dev/null | grep -q "Version:"; then
    echo "[$TOOL] Disponible dans Ubuntu - Installation standard"
    sudo apt install $TOOL
else
    echo "[$TOOL] Installation depuis le dépôt Kali"
    sudo apt install $TOOL/kali-rolling
fi
EOF

# Rendre le script exécutable
chmod +x ~/bin/kali-install

# Ajouter au PATH
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 3-Alias Utiles

Ajouter des alias pratiques pour l'exploration des outils :

```bash
# Ajout des alias au ~/.bashrc
cat >> ~/.bashrc << 'EOF'
# Alias pour les Outils Kali
alias kali-search='apt-cache search --names-only'
alias kali-info='apt-cache show'
alias kali-list='apt list --upgradable | grep kali-rolling'
EOF

# Appliquer les changements
source ~/.bashrc
```

### 4-Protection des Priorités Système

Assurer que les paquets Ubuntu critiques maintiennent la priorité :

```bash
# Protection des paquets Ubuntu critiques
echo 'Package: systemd* ubuntu-* snapd*
Pin: release a=ubuntu
Pin-Priority: 1000' | sudo tee -a /etc/apt/preferences.d/ubuntu-priority.pref
```

### 5-Catégories d'Outils Disponibles

Créer un fichier de référence pour les meta-paquets Kali disponibles :

```bash
cat > ~/kali-packages.txt << 'EOF'
# Meta-paquets Kali Linux Disponibles :
# kali-tools-information-gathering     - Collecte d'informations
# kali-tools-vulnerability             - Analyse de vulnérabilités
# kali-tools-web                       - Tests d'applications web
# kali-tools-passwords                 - Attaques par mots de passe
# kali-tools-wireless                  - Tests de réseaux sans fil
# kali-tools-forensics                 - Analyse forensique
# kali-tools-reverse-engineering       - Rétro-ingénierie
# kali-tools-exploitation              - Exploitation de vulnérabilités
# kali-tools-social-engineering        - Ingénierie sociale
# kali-tools-sniffing-spoofing         - Capture et usurpation
# kali-tools-post-exploitation         - Post-exploitation
# kali-tools-reporting                 - Génération de rapports
EOF
```

## Exemples d'Utilisation

### Installation d'Outils Individuels

```bash
# Rechercher un outil
kali-search nmap

# Obtenir des informations sur un outil
kali-info metasploit-framework

# Installer un outil unique
kali-install burpsuite

# Vérifier la source d'installation
apt-cache policy burpsuite
```

### Installation par Catégorie

```bash
# Installer la suite complète de tests web
sudo apt install kali-tools-web/kali-rolling

# Installer les outils de collecte d'informations
sudo apt install kali-tools-information-gathering/kali-rolling
```

### Vérification du Système

```bash
# Vérifier les outils Kali installés
apt list --installed | grep kali-rolling

# Vérifier l'absence de conflits système
apt-cache policy systemd ubuntu-desktop
```

## Maintenance

### Mises à Jour Régulières

```bash
# Mettre à jour tous les dépôts
sudo apt update

# Nettoyer les paquets inutilisés
sudo apt autoremove

# Vérifier les mises à jour disponibles
sudo apt list --upgradable
```

### Dépannage

```bash
# Vérifier l'état des dépôts
sudo apt update 2>&1 | grep -E "(ERROR|FAIL)"

# Vérifier les clés GPG
apt-key list | grep kali

# Réinitialiser les priorités des paquets si nécessaire
sudo apt-cache policy
```

## Considérations de Sécurité

- **Stabilité du système** : Les paquets Ubuntu maintiennent la priorité pour assurer la stabilité du système
- **Vérification des paquets** : Tous les paquets sont vérifiés via les clés GPG officielles Kali
- **Installation sélective** : Les outils sont installés à la demande, réduisant la surface d'attaque
- **Contrôle des mises à Jour** : Contrôle manuel des outils à installer et mettre à jour

## Avantages

- **Performance native** : Aucune surcharge de virtualisation
- **Accès à la demande** : Installation des outils uniquement quand nécessaire
- **Stabilité du système** : Le système Ubuntu principal reste inaffecté
- **Optimisation ARM64** : Support ARM64 natif pour Apple Silicon
- **Flexibilité** : Basculement facile entre les versions Ubuntu et Kali des outils


## Contribution

N'hésitez pas à contribuer aux améliorations de cette procédure de configuration en soumettant des pull requests ou en signalant des problemes.

---

**Note** : Cette configuration a été testée sur Ubuntu 25 ARM64 (MacBook Pro M3 Pro). Adaptez les chemins et commandes selon vos besoins pour d'autres architectures ou versions Ubuntu.