#!/bin/bash

# Script d'installation Zsh pour serveurs homelab production
# Version avec RAM/CPU explicites en temps réel
# Usage: bash setup_zsh_homelab.sh

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

# Fonction pour installer et configurer Zsh en une seule fois
install_and_configure_zsh() {
    print_step "Installation et configuration Zsh complète..."
    
    # Installation selon l'OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            brew install zsh git curl
        else
            print_warning "Homebrew non installé, utilisation des outils système"
            # Zsh est déjà installé sur macOS récents
        fi
    else
        # Linux
        sudo apt update && sudo apt install -y zsh git curl
    fi
    
    # Création des dossiers
    mkdir -p ~/.zsh/plugins ~/.config/zsh
    
    # Installation plugins en parallèle
    (
        if [[ ! -d ~/.zsh/plugins/zsh-syntax-highlighting ]]; then
            git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/plugins/zsh-syntax-highlighting
        fi
    ) &
    
    (
        if [[ ! -d ~/.zsh/plugins/zsh-autosuggestions ]]; then
            git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
        fi
    ) &
    
    (
        if [[ ! -d ~/.zsh/plugins/zsh-completions ]]; then
            git clone --depth=1 https://github.com/zsh-users/zsh-completions ~/.zsh/plugins/zsh-completions
        fi
    ) &
    
    wait  # Attendre que tous les plugins se téléchargent
    
    print_success "Plugins installés en parallèle"
}

# Fonction pour créer la configuration .zshrc homelab production
create_homelab_zshrc() {
    print_step "Création de la configuration .zshrc homelab..."
    
    # Sauvegarder l'ancien .zshrc s'il existe
    [[ -f ~/.zshrc ]] && cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
    
    # Créer le nouveau .zshrc optimisé
    cat > ~/.zshrc << 'EOF'
# Configuration Zsh pour serveurs homelab production
# Version avec RAM/CPU explicites en temps réel

# ========================================
# CONFIGURATION DE BASE
# ========================================

# Chargement des couleurs et options de base
autoload -U colors && colors
setopt PROMPT_SUBST
setopt AUTO_CD
setopt CORRECT
setopt EXTENDED_GLOB

# Configuration historique optimisée
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# Configuration d'autocomplétion avancée
autoload -U compinit && compinit -u

# ========================================
# CONFIGURATION VISUELLE DES FICHIERS
# ========================================

# Couleurs pour ls optimisées pour serveur
export CLICOLOR=1
export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd

# Configuration LS_COLORS détaillée pour navigation élégante
export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.py=01;33:*.js=01;33:*.json=01;33:*.yml=01;33:*.yaml=01;33:*.toml=01;33:*.ini=01;33:*.cfg=01;33:*.conf=01;33:*.log=00;37:*.md=01;37:*.txt=00;37:*.sh=01;32:*.bash=01;32:*.zsh=01;32:*.fish=01;32'

# Style de complétion avec couleurs
zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%F{blue}── %d ──%f%b'
zstyle ':completion:*:messages' format '%F{green}%d%f'
zstyle ':completion:*:warnings' format '%F{red}No matches for: %d%f'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Complétion insensible à la casse
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Complétion pour sudo
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin

# ========================================
# FONCTIONS SYSTÈME TEMPS RÉEL
# ========================================

# Fonction pour RAM consommée en Go (temps réel explicite)
ram_usage() {
    local ram_used
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - conversion en Go
        local pages_used=$(vm_stat | grep "Pages active\|Pages inactive\|Pages speculative\|Pages wired down" | awk '{sum += $3} END {print sum}' | sed 's/\.//')
        if [[ -n "$pages_used" && $pages_used -gt 0 ]]; then
            # Conversion pages vers Go (page = 4096 bytes sur macOS)
            ram_used=$(echo "scale=1; $pages_used * 4096 / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0.0")
        else
            ram_used="0.0"
        fi
    else
        # Linux - utilisation directe en Go
        if command -v free >/dev/null 2>&1; then
            ram_used=$(free -g | grep Mem | awk '{printf("%.1f", $3)}')
        else
            ram_used="0.0"
        fi
    fi
    echo "%{$fg[cyan]%}RAM: ${ram_used}Go%{$reset_color%}"
}

# Fonction pour CPU en temps réel avec pourcentage explicite
cpu_usage() {
    local cpu_percent
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - utiliser top pour CPU instantané
        cpu_percent=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
        if [[ -z "$cpu_percent" ]]; then
            cpu_percent="0"
        fi
    else
        # Linux - utiliser top ou fallback sur load average
        if command -v top >/dev/null 2>&1; then
            cpu_percent=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
        else
            # Fallback sur load average converti en pourcentage approximatif
            local load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)
            local num_cores=$(nproc 2>/dev/null || echo 1)
            cpu_percent=$(echo "scale=1; $load_avg * 100 / $num_cores" | bc 2>/dev/null || echo "0")
        fi
    fi
    
    # Couleur adaptative selon l'usage CPU
    local cpu_color="green"
    if (( $(echo "$cpu_percent > 70" | bc -l 2>/dev/null || echo 0) )); then
        cpu_color="red"
    elif (( $(echo "$cpu_percent > 40" | bc -l 2>/dev/null || echo 0) )); then
        cpu_color="yellow"
    fi
    
    echo "%{$fg[$cpu_color]%}CPU: ${cpu_percent}%%%{$reset_color%}"
}

# Fonction pour le statut de la dernière commande
command_status() {
    echo "%(?:%{$fg[green]%}✓:%{$fg[red]%}✗)%{$reset_color%}"
}

# Fonction pour l'heure en extrémité droite
current_time() {
    echo "%{$fg[yellow]%}%D{%H:%M:%S}%{$reset_color%}"
}

# ========================================
# THÈMES AVEC INFORMATIONS EXPLICITES
# ========================================

# Fonction pour calculer la largeur du terminal et positionner l'heure à droite
setup_rprompt() {
    # Prompt de droite avec l'heure
    RPROMPT='$(current_time)'
}

# Fonction pour changer de thème
change_prompt() {
    case $1 in
        "light")
            PROMPT='%{$fg[green]%}%1~%{$reset_color%} %{$fg[blue]%}❯%{$reset_color%} '
            RPROMPT='$(current_time)'
            ;;
        "full")
            PROMPT='%{$fg[blue]%}╭─%{$reset_color%} %{$fg[cyan]%}%n%{$reset_color%}%{$fg[white]%}@%{$reset_color%}%{$fg[blue]%}%m%{$reset_color%} %{$fg[white]%}in%{$reset_color%} %{$fg[green]%}%~%{$reset_color%} $(ram_usage) $(cpu_usage)
%{$fg[blue]%}╰─%{$reset_color%}$(command_status) %{$fg[blue]%}❯%{$reset_color%} '
            RPROMPT='$(current_time)'
            ;;
        *)
            echo "Usage: change_prompt [theme]"
            echo ""
            echo "🎨 Thèmes disponibles:"
            echo "  light - Prompt light et minimaliste avec heure à droite"
            echo "  full  - Prompt full avec RAM/CPU explicites et heure à droite (par défaut)"
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

# Syntax Highlighting avec couleurs optimisées
if [[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    
    # Configuration couleurs élégantes et sobres
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
    ZSH_HIGHLIGHT_STYLES[default]=none
    ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=red,bold
    ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=cyan,bold
    ZSH_HIGHLIGHT_STYLES[precommand]=fg=green,underline
    ZSH_HIGHLIGHT_STYLES[commandseparator]=fg=blue,bold
    ZSH_HIGHLIGHT_STYLES[path]=fg=blue,underline
    ZSH_HIGHLIGHT_STYLES[globbing]=fg=magenta,bold
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=yellow
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=yellow
    ZSH_HIGHLIGHT_STYLES[comment]=fg=black,bold
    ZSH_HIGHLIGHT_STYLES[arg0]=fg=green,bold
fi

# Autosuggestions avec style sobre
if [[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
    
    # Configuration autosuggestions élégantes
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,italic"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
    ZSH_AUTOSUGGEST_USE_ASYNC=true
fi

# ========================================
# CONFIGURATION ENVIRONNEMENT
# ========================================

# Variables d'environnement
export EDITOR=nano
export PAGER=less
export PATH="$HOME/.local/bin:$PATH"

# Support UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# macOS spécifique
if [[ "$OSTYPE" == "darwin"* ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

# ========================================
# PROMPT PAR DÉFAUT AVEC HEURE À DROITE
# ========================================

# Configuration du prompt de droite
setup_rprompt

# Prompt par défaut (full) avec RAM/CPU explicites
PROMPT='%{$fg[blue]%}╭─%{$reset_color%} %{$fg[cyan]%}%n%{$reset_color%}%{$fg[white]%}@%{$reset_color%}%{$fg[blue]%}%m%{$reset_color%} %{$fg[white]%}in%{$reset_color%} %{$fg[green]%}%~%{$reset_color%} $(ram_usage) $(cpu_usage)
%{$fg[blue]%}╰─%{$reset_color%}$(command_status) %{$fg[blue]%}❯%{$reset_color%} '

# Prompt de droite avec heure
RPROMPT='$(current_time)'

# ========================================
# UTILITAIRES
# ========================================

# Fonction d'aide
zsh_help() {
    echo "🏠 Configuration Zsh pour serveurs homelab production"
    echo ""
    echo "📋 Commandes principales:"
    echo "  change_prompt [theme] - Changer le thème du prompt"
    echo "  zsh_help              - Afficher cette aide"
    echo ""
    echo "🎨 Thèmes disponibles:"
    echo "  light - Prompt light avec heure à droite"
    echo "  full  - Prompt full avec RAM/CPU temps réel et heure à droite (par défaut)"
    echo ""
    echo "📊 Informations système temps réel:"
    echo "  RAM: XX.XGo - Mémoire consommée en gigaoctets"
    echo "  CPU: XX%    - Pourcentage d'utilisation processeur"
    echo "  Heure       - Affichée à droite du terminal (HH:MM:SS)"
    echo ""
    echo "🔧 Plugins installés:"
    [[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && echo "  ✅ Syntax Highlighting" || echo "  ❌ Syntax Highlighting"
    [[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && echo "  ✅ Autosuggestions" || echo "  ❌ Autosuggestions"
    [[ -d ~/.zsh/plugins/zsh-completions ]] && echo "  ✅ Enhanced Completions" || echo "  ❌ Enhanced Completions"
    echo ""
    echo "📖 Navigation:"
    echo "  - Tab pour l'autocomplétion avec couleurs"
    echo "  - Ctrl+R pour recherche historique"
    echo "  - Suggestions automatiques en gris"
    echo "  - Correction automatique des commandes"
    echo "  - Couleurs adaptatives CPU (vert<40%, jaune<70%, rouge>70%)"
}

# Message de bienvenue
echo "🏠 Configuration Zsh homelab avec monitoring temps réel !"
echo "📚 Tapez 'zsh_help' pour l'aide complète"
echo "🎨 Thème actuel: Full avec RAM/CPU explicites et heure à droite"
EOF

    print_success "Configuration .zshrc homelab créée"
}

# Fonction pour configuration instantanée et persistante
apply_instant_configuration() {
    print_step "Application instantanée et persistante de Zsh..."
    
    # Changer le shell par défaut
    local zsh_path=$(which zsh)
    
    # Ajouter zsh à /etc/shells si nécessaire
    if ! grep -q "^$zsh_path$" /etc/shells; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "$zsh_path" | sudo tee -a /etc/shells
        else
            echo "$zsh_path" | sudo tee -a /etc/shells
        fi
    fi
    
    # Changer le shell par défaut selon l'OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        chsh -s "$zsh_path"
    else
        # Linux
        sudo chsh -s "$zsh_path" "$USER" 2>/dev/null || sudo usermod -s "$zsh_path" "$USER"
    fi
    
    print_success "Shell par défaut configuré"
}

# Fonction pour tester la configuration rapidement
quick_test() {
    print_step "Test rapide de la configuration..."
    
    # Tests essentiels
    command_exists zsh && print_success "Zsh: ✓" || print_error "Zsh: ✗"
    [[ -f ~/.zshrc ]] && print_success "Config: ✓" || print_error "Config: ✗"
    [[ -d ~/.zsh/plugins ]] && print_success "Plugins: ✓" || print_error "Plugins: ✗"
}

# Fonction principale optimisée
main() {
    print_header "INSTALLATION ZSH HOMELAB AVEC MONITORING TEMPS RÉEL"
    
    print_message $CYAN "Installation homelab avec monitoring explicite:"
    echo "  • Zsh avec RAM/CPU en temps réel"
    echo "  • RAM affichée en Go (ex: RAM: 8.2Go)"
    echo "  • CPU en pourcentage avec couleurs (ex: CPU: 45%)"
    echo "  • Heure positionnée à droite du terminal"
    echo "  • Plugins: syntax-highlighting, autosuggestions, completions"
    echo "  • Activation immédiate et persistante"
    echo
    
    read -p "Continuer l'installation ? (Y/n): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Nn]$ ]] && exit 0
    
    # Installation et configuration en une fois
    install_and_configure_zsh
    create_homelab_zshrc
    apply_instant_configuration
    quick_test
    
    print_header "INSTALLATION TERMINÉE"
    print_message $GREEN "🎉 Zsh homelab avec monitoring temps réel prêt !"
    echo
    print_message $CYAN "📋 Configuration appliquée:"
    echo "   ✅ Zsh installé et configuré pour homelab"
    echo "   ✅ Monitoring RAM en Go (temps réel)"
    echo "   ✅ Monitoring CPU en % avec couleurs adaptatives"
    echo "   ✅ Heure affichée à droite du terminal"
    echo "   ✅ Plugins avec couleurs élégantes"
    echo "   ✅ Shell par défaut changé (persistant)"
    echo "   ✅ Thème full par défaut avec toutes les infos"
    echo
    print_message $YELLOW "🚀 Activation immédiate:"
    echo "   • Tapez 'exec zsh' pour activer maintenant"
    echo "   • Ou reconnectez-vous pour activation automatique"
    echo "   • Tapez 'zsh_help' pour voir toutes les options"
    echo
    print_message $PURPLE "📊 Informations temps réel:"
    echo "   • RAM: XX.XGo - Mémoire consommée explicite"
    echo "   • CPU: XX% - Pourcentage avec couleurs (vert/jaune/rouge)"
    echo "   • HH:MM:SS - Heure en temps réel à droite"
    
    # Activation immédiate proposée
    echo
    read -p "Activer Zsh immédiatement ? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        print_message $GREEN "🏠 Lancement de Zsh avec monitoring temps réel..."
        exec zsh
    fi
}

# Gestion des erreurs
trap 'print_error "Erreur installation. Vérifiez les permissions."; exit 1' ERR

# Exécution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
