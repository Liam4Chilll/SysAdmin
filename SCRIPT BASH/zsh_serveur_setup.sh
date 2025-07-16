#!/bin/bash

# Script d'installation complète Zsh avec configuration visuelle
# Pour serveur Ubuntu neuf
# Usage: bash setup_zsh.sh

set -e  # Arrêter le script en cas d'erreur

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonction pour afficher des messages colorés
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo
    print_message $CYAN "=============================================="
    print_message $CYAN "$1"
    print_message $CYAN "=============================================="
    echo
}

print_step() {
    print_message $BLUE "🔧 $1"
}

print_success() {
    print_message $GREEN "✅ $1"
}

print_warning() {
    print_message $YELLOW "⚠️ $1"
}

print_error() {
    print_message $RED "❌ $1"
}

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fonction pour vérifier les droits sudo
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        print_error "Ce script nécessite les droits sudo. Veuillez vous assurer d'avoir les permissions nécessaires."
        exit 1
    fi
}

# Fonction pour détecter la distribution
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        print_error "Impossible de détecter la distribution. Ce script est conçu pour Ubuntu."
        exit 1
    fi
    
    if [[ $OS != *"Ubuntu"* ]]; then
        print_warning "Ce script est optimisé pour Ubuntu. Votre système: $OS"
        read -p "Voulez-vous continuer quand même ? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Fonction pour mettre à jour le système
update_system() {
    print_step "Mise à jour du système..."
    sudo apt update && sudo apt upgrade -y
    print_success "Système mis à jour"
}

# Fonction pour installer les dépendances
install_dependencies() {
    print_step "Installation des dépendances..."
    
    local packages=(
        "zsh"
        "git"
        "curl"
        "wget"
        "build-essential"
        "software-properties-common"
    )
    
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            print_step "Installation de $package..."
            sudo apt install -y "$package"
        else
            print_message $YELLOW "$package est déjà installé"
        fi
    done
    
    print_success "Dépendances installées"
}

# Fonction pour installer Zsh
install_zsh() {
    print_step "Vérification de l'installation de Zsh..."
    
    if command_exists zsh; then
        print_success "Zsh est déjà installé: $(zsh --version)"
    else
        print_step "Installation de Zsh..."
        sudo apt install -y zsh
        print_success "Zsh installé"
    fi
    
    # Vérifier la version
    ZSH_VERSION=$(zsh --version | cut -d' ' -f2)
    print_message $CYAN "Version Zsh installée: $ZSH_VERSION"
}

# Fonction pour changer le shell par défaut
change_default_shell() {
    print_step "Configuration du shell par défaut..."
    
    local current_shell=$(getent passwd $USER | cut -d: -f7)
    local zsh_path=$(which zsh)
    
    if [[ "$current_shell" != "$zsh_path" ]]; then
        print_step "Changement du shell par défaut vers Zsh..."
        chsh -s "$zsh_path"
        print_success "Shell par défaut changé vers Zsh"
        print_warning "Vous devrez vous reconnecter pour que le changement prenne effet"
    else
        print_success "Zsh est déjà le shell par défaut"
    fi
}

# Fonction pour créer les dossiers nécessaires
create_directories() {
    print_step "Création des dossiers de configuration..."
    
    mkdir -p ~/.zsh/plugins
    mkdir -p ~/.zsh/themes
    mkdir -p ~/.config/zsh
    
    print_success "Dossiers créés"
}

# Fonction pour installer les plugins Zsh
install_zsh_plugins() {
    print_step "Installation des plugins Zsh..."
    
    # Plugin: zsh-syntax-highlighting
    if [[ ! -d ~/.zsh/plugins/zsh-syntax-highlighting ]]; then
        print_step "Installation de zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/plugins/zsh-syntax-highlighting
        print_success "zsh-syntax-highlighting installé"
    else
        print_step "Mise à jour de zsh-syntax-highlighting..."
        cd ~/.zsh/plugins/zsh-syntax-highlighting && git pull
        print_success "zsh-syntax-highlighting mis à jour"
    fi
    
    # Plugin: zsh-autosuggestions
    if [[ ! -d ~/.zsh/plugins/zsh-autosuggestions ]]; then
        print_step "Installation de zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
        print_success "zsh-autosuggestions installé"
    else
        print_step "Mise à jour de zsh-autosuggestions..."
        cd ~/.zsh/plugins/zsh-autosuggestions && git pull
        print_success "zsh-autosuggestions mis à jour"
    fi
    
    # Plugin: zsh-completions (bonus)
    if [[ ! -d ~/.zsh/plugins/zsh-completions ]]; then
        print_step "Installation de zsh-completions..."
        git clone https://github.com/zsh-users/zsh-completions ~/.zsh/plugins/zsh-completions
        print_success "zsh-completions installé"
    else
        print_step "Mise à jour de zsh-completions..."
        cd ~/.zsh/plugins/zsh-completions && git pull
        print_success "zsh-completions mis à jour"
    fi
}

# Fonction pour installer Docker (optionnel)
install_docker() {
    read -p "Voulez-vous installer Docker ? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Installation de Docker..."
        
        # Supprimer les anciennes versions
        sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
        
        # Installer les dépendances
        sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        
        # Ajouter la clé GPG officielle de Docker
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Ajouter le repository Docker
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Installer Docker
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # Ajouter l'utilisateur au groupe docker
        sudo usermod -aG docker $USER
        
        # Démarrer et activer Docker
        sudo systemctl start docker
        sudo systemctl enable docker
        
        print_success "Docker installé"
        print_warning "Vous devrez vous reconnecter pour utiliser Docker sans sudo"
    fi
}

# Fonction pour créer la configuration .zshrc
create_zshrc() {
    print_step "Création du fichier de configuration .zshrc..."
    
    # Sauvegarder l'ancien .zshrc s'il existe
    if [[ -f ~/.zshrc ]]; then
        print_step "Sauvegarde de l'ancien .zshrc..."
        cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
        print_success "Ancien .zshrc sauvegardé"
    fi
    
    # Créer le nouveau .zshrc
    cat > ~/.zshrc << 'EOF'
# Configuration Zsh visuelle avec icônes pour serveur Ubuntu
# Généré automatiquement par setup_zsh.sh

# Configuration de base
autoload -U colors && colors
setopt PROMPT_SUBST

# Historique
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

# Configuration d'autocomplétion avancée
autoload -U compinit && compinit -u

# Style de complétion
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Complétion insensible à la casse
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Complétion pour les commandes sudo
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin

# ========================================
# FONCTIONS GIT AVEC ICÔNES
# ========================================

# Fonction Git simple avec icône
git_prompt_simple() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -n $branch ]]; then
    local status=$(git status --porcelain 2>/dev/null)
    local git_status=""
    
    if [[ -n $status ]]; then
      git_status="%{$fg[red]%}●%{$reset_color%}"
    else
      git_status="%{$fg[green]%}●%{$reset_color%}"
    fi
    
    echo " %{$fg[blue]%} (%{$fg[yellow]%}$branch%{$fg[blue]%}) $git_status"
  fi
}

# Fonction Git détaillée avec symboles
git_prompt_detailed() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -n $branch ]]; then
    local status=$(git status --porcelain 2>/dev/null)
    local staged=$(echo "$status" | grep -E '^[MADRC]' | wc -l)
    local unstaged=$(echo "$status" | grep -E '^.[MD]' | wc -l)
    local untracked=$(echo "$status" | grep -E '^\?\?' | wc -l)
    local stash=$(git stash list 2>/dev/null | wc -l)
    
    local git_info=" %{$fg[blue]%} (%{$fg[yellow]%}$branch%{$reset_color%}"
    
    # Modifications staged (prêtes à être commitées)
    if [[ $staged -gt 0 ]]; then
      git_info="$git_info %{$fg[green]%}+$staged%{$reset_color%}"
    fi
    
    # Modifications non staged (modifiées mais pas ajoutées)
    if [[ $unstaged -gt 0 ]]; then
      git_info="$git_info %{$fg[red]%}!$unstaged%{$reset_color%}"
    fi
    
    # Fichiers non trackés
    if [[ $untracked -gt 0 ]]; then
      git_info="$git_info %{$fg[yellow]%}?$untracked%{$reset_color%}"
    fi
    
    # Stash
    if [[ $stash -gt 0 ]]; then
      git_info="$git_info %{$fg[magenta]%}⚑$stash%{$reset_color%}"
    fi
    
    git_info="$git_info%{$reset_color%}$(git_upstream)%{$fg[blue]%})%{$reset_color%}"
    echo $git_info
  fi
}

# Fonction Git complète avec tous les symboles
git_prompt_complete() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -n $branch ]]; then
    local status=$(git status --porcelain 2>/dev/null)
    local staged=$(echo "$status" | grep -E '^[MADRC]' | wc -l)
    local unstaged=$(echo "$status" | grep -E '^.[MD]' | wc -l)
    local untracked=$(echo "$status" | grep -E '^\?\?' | wc -l)
    local stash=$(git stash list 2>/dev/null | wc -l)
    local conflicts=$(echo "$status" | grep -E '^UU|^AA|^DD' | wc -l)
    
    local git_info=" %{$fg[blue]%} (%{$fg[yellow]%}$branch%{$reset_color%}"
    
    # Modifications staged (✓ = prêt à commit)
    if [[ $staged -gt 0 ]]; then
      git_info="$git_info %{$fg[green]%}✓$staged%{$reset_color%}"
    fi
    
    # Modifications non staged (△ = modifié)
    if [[ $unstaged -gt 0 ]]; then
      git_info="$git_info %{$fg[red]%}△$unstaged%{$reset_color%}"
    fi
    
    # Fichiers non trackés (+ = nouveau)
    if [[ $untracked -gt 0 ]]; then
      git_info="$git_info %{$fg[yellow]%}+$untracked%{$reset_color%}"
    fi
    
    # Conflits (✗ = conflit)
    if [[ $conflicts -gt 0 ]]; then
      git_info="$git_info %{$fg[red]%}✗$conflicts%{$reset_color%}"
    fi
    
    # Stash (⚑ = stash)
    if [[ $stash -gt 0 ]]; then
      git_info="$git_info %{$fg[magenta]%}⚑$stash%{$reset_color%}"
    fi
    
    git_info="$git_info%{$reset_color%}$(git_upstream)%{$fg[blue]%})%{$reset_color%}"
    echo $git_info
  fi
}

# Fonction pour la branche upstream avec symboles
git_upstream() {
  local upstream=$(git rev-parse --abbrev-ref @{upstream} 2>/dev/null)
  if [[ -n $upstream ]]; then
    local ahead=$(git rev-list --count @{upstream}..HEAD 2>/dev/null)
    local behind=$(git rev-list --count HEAD..@{upstream} 2>/dev/null)
    
    if [[ $ahead -gt 0 && $behind -gt 0 ]]; then
      echo " %{$fg[yellow]%}↕$ahead/$behind%{$reset_color%}"
    elif [[ $ahead -gt 0 ]]; then
      echo " %{$fg[green]%}↑$ahead%{$reset_color%}"
    elif [[ $behind -gt 0 ]]; then
      echo " %{$fg[red]%}↓$behind%{$reset_color%}"
    else
      echo " %{$fg[green]%}≡%{$reset_color%}"
    fi
  fi
}

# ========================================
# FONCTIONS DOCKER AVEC ICÔNES
# ========================================

# Fonction Docker simple avec icône baleine
docker_prompt_simple() {
  if command -v docker &> /dev/null; then
    if docker info &> /dev/null 2>&1; then
      local containers=$(docker ps -q 2>/dev/null | wc -l)
      if [[ $containers -gt 0 ]]; then
        echo " %{$fg[blue]%}🐳 $containers%{$reset_color%}"
      else
        echo " %{$fg[cyan]%}🐳%{$reset_color%}"
      fi
    fi
  fi
}

# Fonction Docker détaillée
docker_prompt_detailed() {
  if command -v docker &> /dev/null; then
    if docker info &> /dev/null 2>&1; then
      local running=$(docker ps -q 2>/dev/null | wc -l)
      local stopped=$(docker ps -aq --filter "status=exited" 2>/dev/null | wc -l)
      local images=$(docker images -q 2>/dev/null | wc -l)
      
      local docker_info=" %{$fg[blue]%}🐳"
      
      # Conteneurs en cours d'exécution
      if [[ $running -gt 0 ]]; then
        docker_info="$docker_info %{$fg[green]%}▶$running%{$reset_color%}"
      fi
      
      # Conteneurs arrêtés
      if [[ $stopped -gt 0 ]]; then
        docker_info="$docker_info %{$fg[red]%}■$stopped%{$reset_color%}"
      fi
      
      # Images
      if [[ $images -gt 0 ]]; then
        docker_info="$docker_info %{$fg[cyan]%}📦$images%{$reset_color%}"
      fi
      
      echo "$docker_info%{$reset_color%}"
    fi
  fi
}

# Fonction Docker complète avec Swarm
docker_prompt_complete() {
  if command -v docker &> /dev/null; then
    if docker info &> /dev/null 2>&1; then
      local running=$(docker ps -q 2>/dev/null | wc -l)
      local stopped=$(docker ps -aq --filter "status=exited" 2>/dev/null | wc -l)
      local images=$(docker images -q 2>/dev/null | wc -l)
      local networks=$(docker network ls -q 2>/dev/null | wc -l)
      local volumes=$(docker volume ls -q 2>/dev/null | wc -l)
      
      # Vérifier si Docker Swarm est actif
      local swarm_status=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null)
      
      local docker_info=" %{$fg[blue]%}🐳"
      
      # Conteneurs en cours d'exécution (▶ = running)
      if [[ $running -gt 0 ]]; then
        docker_info="$docker_info %{$fg[green]%}▶$running%{$reset_color%}"
      fi
      
      # Conteneurs arrêtés (■ = stopped)
      if [[ $stopped -gt 0 ]]; then
        docker_info="$docker_info %{$fg[red]%}■$stopped%{$reset_color%}"
      fi
      
      # Images (📦 = images)
      if [[ $images -gt 0 ]]; then
        docker_info="$docker_info %{$fg[cyan]%}📦$images%{$reset_color%}"
      fi
      
      # Réseaux (🌐 = networks)
      if [[ $networks -gt 3 ]]; then  # Plus que les réseaux par défaut
        docker_info="$docker_info %{$fg[yellow]%}🌐$((networks-3))%{$reset_color%}"
      fi
      
      # Volumes (💾 = volumes)
      if [[ $volumes -gt 0 ]]; then
        docker_info="$docker_info %{$fg[magenta]%}💾$volumes%{$reset_color%}"
      fi
      
      # Swarm (⚡ = swarm active)
      if [[ "$swarm_status" == "active" ]]; then
        docker_info="$docker_info %{$fg[yellow]%}⚡%{$reset_color%}"
      fi
      
      echo "$docker_info%{$reset_color%}"
    fi
  fi
}

# ========================================
# FONCTIONS SYSTÈME
# ========================================

# Fonction pour l'heure
current_time() {
  echo "%{$fg[yellow]%}🕐 %D{%H:%M:%S}%{$reset_color%}"
}

# Fonction pour le statut de la dernière commande
last_command_status() {
  echo "%(?:%{$fg[green]%}✓:%{$fg[red]%}✗)%{$reset_color%}"
}

# Fonction pour afficher des informations système
system_info() {
  local load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)
  local memory_usage=$(free | grep Mem | awk '{printf("%.0f%%", $3/$2 * 100.0)}')
  local disk_usage=$(df -h / | awk 'NR==2{printf "%s", $5}')
  
  echo " %{$fg[cyan]%}💻 Load:$load_avg Mem:$memory_usage Disk:$disk_usage%{$reset_color%}"
}

# ========================================
# THÈMES DE PROMPT
# ========================================

# Fonction pour changer de thème
change_prompt() {
  case $1 in
    "minimal")
      PROMPT='%{$fg[green]%}%1~%{$reset_color%}$(git_prompt_simple)$(docker_prompt_simple) %{$fg[blue]%}❯%{$reset_color%} '
      ;;
    "standard")
      PROMPT='%{$fg[cyan]%}%n%{$reset_color%} %{$fg[white]%}@%{$reset_color%} %{$fg[magenta]%}%m%{$reset_color%} %{$fg[white]%}in%{$reset_color%} %{$fg[green]%}%~%{$reset_color%}$(git_prompt_detailed)$(docker_prompt_detailed)
%{$fg[blue]%}❯%{$reset_color%} '
      ;;
    "complete")
      PROMPT='%{$fg[cyan]%}%n%{$reset_color%} %{$fg[white]%}@%{$reset_color%} %{$fg[magenta]%}%m%{$reset_color%} %{$fg[white]%}in%{$reset_color%} %{$fg[green]%}%~%{$reset_color%}$(git_prompt_complete)$(docker_prompt_complete)
%{$fg[blue]%}❯%{$reset_color%} '
      ;;
    "server")
      PROMPT='%{$fg[blue]%}┌─%{$reset_color%} %{$fg[cyan]%}%n%{$reset_color%}%{$fg[white]%}@%{$reset_color%}%{$fg[magenta]%}%m%{$reset_color%} %{$fg[white]%}in%{$reset_color%} %{$fg[green]%}%~%{$reset_color%}$(git_prompt_complete)$(docker_prompt_complete)
%{$fg[blue]%}└─❯%{$reset_color%} '
      ;;
    "devops")
      PROMPT='%{$fg[blue]%}┌─%{$reset_color%} %{$fg[cyan]%}%n%{$reset_color%}%{$fg[white]%}@%{$reset_color%}%{$fg[magenta]%}%m%{$reset_color%} %{$fg[white]%}in%{$reset_color%} %{$fg[green]%}%~%{$reset_color%}$(git_prompt_complete)$(docker_prompt_complete)
%{$fg[blue]%}└─❯%{$reset_color%} '
      ;;
    "time")
      PROMPT='$(current_time) %{$fg[cyan]%}%n%{$reset_color%}%{$fg[white]%}@%{$reset_color%}%{$fg[magenta]%}%m%{$reset_color%} %{$fg[white]%}in%{$reset_color%} %{$fg[green]%}%~%{$reset_color%}$(git_prompt_complete)$(docker_prompt_complete)
$(last_command_status) %{$fg[blue]%}❯%{$reset_color%} '
      ;;
    "dashboard")
      PROMPT='%{$fg[blue]%}╭─%{$reset_color%} %{$fg[cyan]%}%n%{$reset_color%}%{$fg[white]%}@%{$reset_color%}%{$fg[magenta]%}%m%{$reset_color%} %{$fg[white]%}in%{$reset_color%} %{$fg[green]%}%~%{$reset_color%}$(git_prompt_complete)$(docker_prompt_complete)$(system_info)
%{$fg[blue]%}╰─❯%{$reset_color%} '
      ;;
    *)
      echo "Usage: change_prompt [theme]"
      echo ""
      echo "🎨 Thèmes disponibles:"
      echo "  minimal   - Prompt simple avec icônes Git et Docker"
      echo "  standard  - Prompt standard avec informations détaillées"
      echo "  complete  - Prompt avec tous les symboles Git et Docker"
      echo "  server    - Thème optimisé pour serveur avec bordures"
      echo "  devops    - Thème spécialisé pour DevOps"
      echo "  time      - Prompt avec heure et statut des commandes"
      echo "  dashboard - Prompt avec informations système complètes"
      echo ""
      echo "🔤 Légende des symboles Git:"
      echo "   = icône Git"
      echo "  ✓ = modifications staged (prêtes à commit)"
      echo "  △ = modifications non staged"
      echo "  + = fichiers non trackés"
      echo "  ✗ = conflits"
      echo "  ⚑ = stash"
      echo "  ↑ = commits en avance"
      echo "  ↓ = commits en retard"
      echo "  ↕ = divergence"
      echo "  ≡ = à jour"
      echo ""
      echo "🐳 Légende des symboles Docker:"
      echo "  🐳 = icône Docker"
      echo "  ▶ = conteneurs en cours"
      echo "  ■ = conteneurs arrêtés"
      echo "  📦 = images"
      echo "  🌐 = réseaux"
      echo "  💾 = volumes"
      echo "  ⚡ = Swarm actif"
      ;;
  esac
}

# ========================================
# PLUGINS EXTERNES
# ========================================

# Completions supplémentaires
if [[ -d ~/.zsh/plugins/zsh-completions ]]; then
  fpath=(~/.zsh/plugins/zsh-completions/src $fpath)
fi

# Syntax Highlighting
if [[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  
  # Configuration des couleurs personnalisées
  ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
  ZSH_HIGHLIGHT_STYLES[default]=none
  ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=red,bold
  ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=cyan,bold
  ZSH_HIGHLIGHT_STYLES[precommand]=fg=green,underline
  ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=blue,bold
  ZSH_HIGHLIGHT_STYLES[path]=underline
  ZSH_HIGHLIGHT_STYLES[globbing]=fg=blue,bold
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
  ZSH_HIGHLIGHT_STYLES[comment]=fg=black,bold
  ZSH_HIGHLIGHT_STYLES[arg0]=fg=green
fi

# Autosuggestions
if [[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
  
  # Configuration des autosuggestions
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,italic"
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
  ZSH_AUTOSUGGEST_USE_ASYNC=true
fi

# ========================================
# CONFIGURATION ENVIRONNEMENT
# ========================================

# Couleurs pour ls
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Variables d'environnement pour Ubuntu
export EDITOR=nano
export PAGER=less
export BROWSER=w3m

# PATH personnalisé
export PATH="$HOME/.local/bin:$PATH"

# Support UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ========================================
# SECTION ALIASES (VIDE - PRÊTE POUR VOS AJOUTS)
# ========================================

# Vous pouvez ajouter vos aliases personnalisés ici
# Exemple:
# alias ll='ls -la'
# alias gs='git status'
# alias dps='docker ps'

# ========================================
# PROMPT PAR DÉFAUT SERVEUR
# ========================================

# Prompt par défaut optimisé pour serveur
PROMPT='%{$fg[blue]%}┌─%{$reset_color%} %{$fg[cyan]%}%n%{$reset_color%}%{$fg[white]%}@%{$reset_color%}%{$fg[magenta]%}%m%{$reset_color%} %{$fg[white]%}in%{$reset_color%} %{$fg[green]%}%~%{$reset_color%}$(git_prompt_detailed)$(docker_prompt_detailed)
%{$fg[blue]%}└─❯%{$reset_color%} '

# ========================================
# UTILITAIRES
# ========================================

# Raccourcis pour la configuration
alias zshconfig="$EDITOR ~/.zshrc"
alias zshreload="source ~/.zshrc"

# Fonction d'aide
zsh_help() {
  echo "🚀 Configuration Zsh pour serveur Ubuntu"
  echo ""
  echo "📋 Commandes principales:"
  echo "  change_prompt [theme] - Changer le thème du prompt"
  echo "  zsh_help              - Afficher cette aide"
  echo "  zshconfig             - Éditer la configuration"
  echo "  zshreload             - Recharger la configuration"
  echo ""
  echo "🎨 Thèmes disponibles:"
  echo "  minimal, standard, complete, server, devops, time, dashboard"
  echo ""
  echo "🔧 Plugins installés:"
  [[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && echo "  ✅ Syntax Highlighting" || echo "  ❌ Syntax Highlighting"
  [[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && echo "  ✅ Autosuggestions" || echo "  ❌ Autosuggestions"
  [[ -f ~/.zsh/plugins/zsh-completions/zsh-completions.plugin.zsh ]] && echo "  ✅ Enhanced Completions" || echo "  ❌ Enhanced Completions"
  echo ""
  echo "🐳 Docker installé:" $(command -v docker &> /dev/null && echo "✅ Oui" || echo "❌ Non")
  echo ""
  echo "📖 Aide rapide:"
  echo "  - Tapez 'Tab' pour l'autocomplétion"
  echo "  - Utilisez les flèches pour naviguer dans l'historique"
  echo "  - Les suggestions apparaissent automatiquement en gris"
  echo "  - Appuyez sur 'Ctrl+R' pour la recherche dans l'historique"
}

# Message de bienvenue
echo "🎨 Configuration Zsh pour serveur Ubuntu chargée !"
echo "📚 Tapez 'zsh_help' pour l'aide complète"
echo "🎨 Tapez 'change_prompt server' pour le thème serveur optimisé"
EOF

    print_success "Fichier .zshrc créé"
}

# Fonction pour configurer Git (optionnel)
configure_git() {
    read -p "Voulez-vous configurer Git ? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Configuration de Git..."
        
        read -p "Nom d'utilisateur Git: " git_name
        read -p "Email Git: " git_email
        
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        
        print_success "Git configuré"
    fi
}

# Fonction pour tester la configuration
test_configuration() {
    print_step "Test de la configuration..."
    
    # Tester Zsh
    if command_exists zsh; then
        print_success "Zsh: OK"
    else
        print_error "Zsh: ERREUR"
    fi
    
    # Tester Git
    if command_exists git; then
        print_success "Git: OK"
    else
        print_warning "Git: Non installé"
    fi
    
    # Tester Docker
    if command_exists docker; then
        print_success "Docker: OK"
    else
        print_warning "Docker: Non installé"
    fi
    
    # Tester les plugins
    if [[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
        print_success "Plugin Syntax Highlighting: OK"
    else
        print_error "Plugin Syntax Highlighting: ERREUR"
    fi
    
    if [[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
        print_success "Plugin Autosuggestions: OK"
    else
        print_error "Plugin Autosuggestions: ERREUR"
    fi
    
    # Tester le fichier .zshrc
    if [[ -f ~/.zshrc ]]; then
        print_success "Fichier .zshrc: OK"
    else
        print_error "Fichier .zshrc: ERREUR"
    fi
}

# Fonction pour créer un script de désinstallation
create_uninstall_script() {
    print_step "Création du script de désinstallation..."
    
    cat > ~/uninstall_zsh.sh << 'EOF'
#!/bin/bash
# Script de désinstallation Zsh

echo "🗑️  Désinstallation de la configuration Zsh..."

# Restaurer le shell par défaut
chsh -s /bin/bash

# Sauvegarder puis supprimer la configuration
if [[ -f ~/.zshrc ]]; then
    mv ~/.zshrc ~/.zshrc.uninstalled.$(date +%Y%m%d_%H%M%S)
    echo "✅ Configuration .zshrc sauvegardée"
fi

# Supprimer les plugins (optionnel)
read -p "Voulez-vous supprimer les plugins Zsh ? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf ~/.zsh/plugins
    echo "✅ Plugins supprimés"
fi

# Supprimer Zsh (optionnel)
read -p "Voulez-vous désinstaller Zsh complètement ? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo apt remove -y zsh
    echo "✅ Zsh désinstallé"
fi

echo "🎯 Désinstallation terminée. Reconnectez-vous pour que les changements prennent effet."
EOF

    chmod +x ~/uninstall_zsh.sh
    print_success "Script de désinstallation créé: ~/uninstall_zsh.sh"
}

# Fonction pour afficher les informations finales
show_final_info() {
    print_header "INSTALLATION TERMINÉE"
    
    print_message $GREEN "🎉 Installation de Zsh terminée avec succès !"
    echo
    print_message $CYAN "📋 Résumé de l'installation:"
    echo "   ✅ Zsh installé et configuré"
    echo "   ✅ Plugins installés (syntax-highlighting, autosuggestions, completions)"
    echo "   ✅ Configuration visuelle avec icônes Git et Docker"
    echo "   ✅ Shell par défaut changé vers Zsh"
    [[ $(command -v docker) ]] && echo "   ✅ Docker installé" || echo "   ❌ Docker non installé"
    echo
    print_message $YELLOW "📖 Prochaines étapes:"
    echo "   1. Reconnectez-vous pour que Zsh devienne actif"
    echo "   2. Tapez 'zsh_help' pour voir toutes les options"
    echo "   3. Utilisez 'change_prompt [theme]' pour changer l'apparence"
    echo "   4. Ajoutez vos aliases dans la section dédiée du .zshrc"
    echo
    print_message $CYAN "🎨 Thèmes recommandés pour serveur:"
    echo "   • change_prompt server    (optimisé serveur)"
    echo "   • change_prompt devops    (pour DevOps)"
    echo "   • change_prompt dashboard (avec infos système)"
    echo
    print_message $PURPLE "🔧 Fichiers créés:"
    echo "   • ~/.zshrc (configuration principale)"
    echo "   • ~/.zsh/plugins/ (dossier des plugins)"
    echo "   • ~/uninstall_zsh.sh (script de désinstallation)"
    echo
    print_message $BLUE "💡 Conseils:"
    echo "   • Utilisez Tab pour l'autocomplétion"
    echo "   • Ctrl+R pour rechercher dans l'historique"
    echo "   • Les suggestions apparaissent en gris"
    echo "   • Tapez 'zshconfig' pour éditer la configuration"
    echo
}

# Fonction principale
main() {
    print_header "INSTALLATION ZSH POUR SERVEUR UBUNTU"
    
    print_message $CYAN "Ce script va installer et configurer:"
    echo "  • Zsh avec configuration visuelle"
    echo "  • Plugins: syntax-highlighting, autosuggestions, completions"
    echo "  • Support Git avec icônes et symboles"
    echo "  • Support Docker avec informations d'infrastructure"
    echo "  • Docker (optionnel)"
    echo
    
    read -p "Voulez-vous continuer ? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_message $YELLOW "Installation annulée."
        exit 0
    fi
    
    # Vérifications préliminaires
    detect_os
    check_sudo
    
    # Installation
    update_system
    install_dependencies
    install_zsh
    create_directories
    install_zsh_plugins
    create_zshrc
    
    # Optionnels
    install_docker
    configure_git
    
    # Finalisation
    change_default_shell
    create_uninstall_script
    test_configuration
    show_final_info
    
    print_message $GREEN "🚀 Installation terminée ! Reconnectez-vous pour utiliser Zsh."
    print_message $CYAN "📚 N'oubliez pas de taper 'zsh_help' après reconnexion !"
}

# Gestion des erreurs
trap 'print_error "Une erreur est survenue. Installation interrompue."; exit 1' ERR

# Vérifier si le script est exécuté directement
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi