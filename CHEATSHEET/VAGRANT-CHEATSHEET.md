# Vagrant Cheatsheet

## Installation et Configuration Initiale

### Installation
```bash
# macOS (avec Homebrew)
brew install --cask vagrant

# Ubuntu/Debian
sudo apt update && sudo apt install vagrant

# Windows
# Télécharger depuis https://www.vagrantup.com/downloads
```

### Initialisation d'un projet
```bash
# Créer un Vagrantfile basique
vagrant init

# Initialiser avec une box spécifique
vagrant init ubuntu/bionic64
vagrant init centos/7
vagrant init hashicorp/bionic64
```

## Commandes de Base

### Gestion des Machines Virtuelles
```bash
# Démarrer la VM
vagrant up

# Arrêter la VM
vagrant halt

# Redémarrer la VM
vagrant reload

# Suspendre la VM
vagrant suspend

# Reprendre une VM suspendue
vagrant resume

# Détruire la VM
vagrant destroy

# Détruire sans confirmation
vagrant destroy -f
```

### Connexion et Accès
```bash
# Se connecter en SSH
vagrant ssh

# Se connecter à une VM spécifique (multi-machine)
vagrant ssh nom_machine

# Exécuter une commande sans se connecter
vagrant ssh -c "commande"
```

### Statut et Information
```bash
# Voir le statut des VMs
vagrant status

# Statut global de toutes les VMs Vagrant
vagrant global-status

# Nettoyer le cache du statut global
vagrant global-status --prune

# Voir la configuration SSH
vagrant ssh-config
```

## Gestion des Boxes

### Recherche et Installation
```bash
# Lister les boxes installées
vagrant box list

# Ajouter une box
vagrant box add ubuntu/bionic64

# Ajouter une box avec un nom personnalisé
vagrant box add ma-box ubuntu/bionic64

# Rechercher des boxes (nécessite vagrant-cloud plugin)
vagrant cloud search ubuntu
```

### Mise à jour et Suppression
```bash
# Mettre à jour une box
vagrant box update

# Supprimer une box
vagrant box remove ubuntu/bionic64

# Supprimer une version spécifique
vagrant box remove ubuntu/bionic64 --box-version 20210415.0.0
```

## Configuration Vagrantfile

### Structure de Base
```ruby
Vagrant.configure("2") do |config|
  # Box à utiliser
  config.vm.box = "ubuntu/bionic64"
  
  # Version de la box (optionnel)
  config.vm.box_version = "20210415.0.0"
  
  # Nom de la machine
  config.vm.hostname = "mon-serveur"
  
  # Configuration réseau
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.network "public_network"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  
  # Dossiers partagés
  config.vm.synced_folder ".", "/vagrant"
  config.vm.synced_folder "./data", "/opt/data"
  
  # Configuration du provider
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
    vb.cpus = 2
    vb.name = "ma-vm"
  end
  
  # Provisioning
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y nginx
  SHELL
end
```

### Configuration Multi-Machine
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  
  config.vm.define "web" do |web|
    web.vm.hostname = "web-server"
    web.vm.network "private_network", ip: "192.168.56.10"
    web.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
    end
  end
  
  config.vm.define "db" do |db|
    db.vm.hostname = "db-server"
    db.vm.network "private_network", ip: "192.168.56.11"
    db.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
    end
  end
end
```

## Provisioning

### Shell Provisioning
```ruby
# Inline
config.vm.provision "shell", inline: <<-SHELL
  apt-get update
  apt-get install -y apache2
SHELL

# Script externe
config.vm.provision "shell", path: "bootstrap.sh"

# Avec privilèges utilisateur
config.vm.provision "shell", privileged: false, inline: <<-SHELL
  echo "Commande utilisateur"
SHELL

# Avec arguments
config.vm.provision "shell", path: "script.sh", args: ["arg1", "arg2"]
```

### Ansible Provisioning
```ruby
config.vm.provision "ansible" do |ansible|
  ansible.playbook = "playbook.yml"
  ansible.inventory_path = "inventory"
  ansible.limit = "all"
end
```

### Docker Provisioning
```ruby
config.vm.provision "docker" do |d|
  d.build_image "/vagrant/app"
  d.run "nginx", args: "-p 80:80"
end
```

## Réseaux

### Types de Réseau
```ruby
# Réseau privé (Host-only)
config.vm.network "private_network", ip: "192.168.56.10"

# DHCP automatique
config.vm.network "private_network", type: "dhcp"

# Réseau public (Bridged)
config.vm.network "public_network"

# Avec interface spécifique
config.vm.network "public_network", bridge: "en0: Wi-Fi (AirPort)"

# Redirection de ports
config.vm.network "forwarded_port", guest: 80, host: 8080
config.vm.network "forwarded_port", guest: 3306, host: 3306, protocol: "tcp"
```

## Dossiers Partagés

### Types de Partage
```ruby
# Partage par défaut
config.vm.synced_folder ".", "/vagrant"

# Partage personnalisé
config.vm.synced_folder "./src", "/var/www/html"

# NFS (plus rapide sur macOS/Linux)
config.vm.synced_folder ".", "/vagrant", type: "nfs"

# SMB (Windows)
config.vm.synced_folder ".", "/vagrant", type: "smb"

# rsync (unidirectionnel)
config.vm.synced_folder ".", "/vagrant", type: "rsync"

# Désactiver un dossier partagé
config.vm.synced_folder ".", "/vagrant", disabled: true
```

## Plugins Utiles

### Installation et Gestion
```bash
# Installer un plugin
vagrant plugin install nom-plugin

# Lister les plugins installés
vagrant plugin list

# Mettre à jour les plugins
vagrant plugin update

# Désinstaller un plugin
vagrant plugin uninstall nom-plugin
```

### Plugins Populaires
```bash
# Gestion automatique des additions invité VirtualBox
vagrant plugin install vagrant-vbguest

# Interface web pour Vagrant
vagrant plugin install vagrant-manager

# Support amélioré pour Windows
vagrant plugin install vagrant-winnfsd

# Gestion des hosts automatique
vagrant plugin install vagrant-hostmanager

# Mise en cache des boxes
vagrant plugin install vagrant-cachier
```

## Dépannage

### Commandes de Debug
```bash
# Mode verbeux
vagrant up --debug

# Recharger avec provisioning
vagrant reload --provision

# Forcer le provisioning
vagrant provision

# Valider le Vagrantfile
vagrant validate

# Version de Vagrant
vagrant version
```

### Problèmes Courants
```bash
# Réinitialiser une VM corrompue
vagrant destroy && vagrant up

# Problèmes de réseau VirtualBox
sudo /Library/Application\ Support/VirtualBox/LaunchDaemons/VirtualBoxStartup.sh restart

# Nettoyer les VMs orphelines
VBoxManage list vms
VBoxManage unregistervm "nom-vm" --delete

# Problèmes de permissions NFS (macOS)
sudo vim /etc/exports
# Ajouter: /Users -alldirs -mapall=501:20 localhost
```

## Configuration Avancée

### Variables d'Environnement
```ruby
# Dans le Vagrantfile
config.vm.provision "shell", env: {
  "DB_PASSWORD" => ENV["DB_PASSWORD"]
}
```

### Conditions et Boucles
```ruby
Vagrant.configure("2") do |config|
  (1..3).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.box = "ubuntu/bionic64"
      node.vm.network "private_network", ip: "192.168.56.#{10+i}"
    end
  end
end
```

### Hooks et Triggers
```ruby
config.trigger.before :up do |trigger|
  trigger.info = "Démarrage de la VM..."
  trigger.run = {inline: "echo 'Préparation...'"}
end

config.trigger.after :destroy do |trigger|
  trigger.info = "Nettoyage post-destruction"
  trigger.run = {inline: "echo 'VM détruite'"}
end
```

## Bonnes Pratiques

### Optimisation des Performances
- Utiliser NFS pour les dossiers partagés sur macOS/Linux
- Allouer suffisamment de RAM mais pas trop
- Désactiver les dossiers partagés non nécessaires
- Utiliser le cache des boxes avec vagrant-cachier

### Sécurité
- Changer les mots de passe par défaut
- Utiliser des clés SSH personnalisées
- Limiter les redirections de ports
- Utiliser des réseaux privés quand possible

### Organisation
- Versionner le Vagrantfile
- Utiliser des scripts de provisioning externes
- Documenter les dépendances et prérequis
- Tester sur différents providers