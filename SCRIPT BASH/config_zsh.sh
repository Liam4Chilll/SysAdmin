#!/bin/bash

# Script de pré-configuration Zsh pour éviter zsh-newuser-install
# À exécuter AVANT le script principal sur serveurs neufs
# Usage: bash pre_zsh_setup.sh

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_step() {
    print_message $BLUE "🔧 $1"
}

print_success() {
    print_message $GREEN "✅ $1"
}

# Fonction principale
main() {
    print_message $CYAN "🚀 Pré-configuration Zsh pour éviter zsh-newuser-install"
    echo
    
    # Installer Zsh d'abord si pas installé
    if ! command -v zsh &> /dev/null; then
        print_step "Installation de Zsh..."
        sudo apt update && sudo apt install -y zsh
    fi
    
    # Créer immédiatement un .zshrc pour éviter zsh-newuser-install
    print_step "Création du .zshrc préventif..."
    cat > ~/.zshrc << 'EOF'
# Configuration Zsh pour serveur Ubuntu
# Cette configuration évite zsh-newuser-install

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

# Autocomplétion
autoload -U compinit && compinit -u
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Fonction Git avec icône
git_prompt() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -n $branch ]]; then
    local status=$(git status --porcelain 2>/dev/null)
    if [[ -n $status ]]; then
      echo " %{$fg[blue]%} (%{$fg[yellow]%}$branch%{$fg[blue]%}) %{$fg[red]%}●%{$reset_color%}"
    else
      echo " %{$fg[blue]%} (%{$fg[yellow]%}$branch%{$fg[blue]%}) %{$fg[green]%}●%{$reset_color%}"
    fi
  fi
}

# Fonction Docker avec icône baleine
docker_prompt() {
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

# Prompt pour serveur
PROMPT='%{$fg[cyan]%}%n%{$reset_color%}@%{$fg[magenta]%}%m%{$reset_color%} %{$fg[green]%}%~%{$reset_color%}$(git_prompt)$(docker_prompt)
%{$fg[blue]%}❯%{$reset_color%} '

# Variables d'environnement
export EDITOR=nano
export LANG=en_US.UTF-8

# Section aliases (vide pour vos ajouts)
# Ajoutez vos aliases ici

# Utilitaires
alias zshconfig="$EDITOR ~/.zshrc"
alias zshreload="source ~/.zshrc"

echo "🎨 Configuration Zsh de base chargée !"
echo "💡 Utilisez le script setup_zsh.sh pour la configuration complète"
EOF
    
    # Créer les autres fichiers de configuration pour éviter le prompt
    print_step "Création des fichiers de configuration Zsh..."
    touch ~/.zshenv ~/.zprofile ~/.zlogin
    
    # Ajouter Zsh à /etc/shells si nécessaire
    local zsh_path=$(which zsh)
    if ! grep -q "^$zsh_path$" /etc/shells; then
        print_step "Ajout de Zsh à /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi
    
    # Changer le shell par défaut
    print_step "Configuration du shell par défaut..."
    sudo chsh -s "$zsh_path" "$USER" 2>/dev/null || sudo usermod -s "$zsh_path" "$USER"
    
    print_success "Pré-configuration terminée !"
    echo
    print_message $CYAN "✨ Maintenant vous pouvez :"
    echo "   1. Exécuter 'exec zsh' pour tester immédiatement"
    echo "   2. Lancer le script setup_zsh.sh complet"
    echo "   3. Redémarrer le serveur sans voir zsh-newuser-install"
    echo
    
    # Test immédiat
    read -p "Voulez-vous tester Zsh maintenant ? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        print_message $GREEN "🎉 Lancement de Zsh..."
        exec zsh
    fi
}

main "$@"