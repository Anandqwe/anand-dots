# ── Oh My Zsh ─────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""

# Plugins
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    colored-man-pages
    sudo
    archlinux
    copypath
    dirhistory
)

# ── Environment ────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"
export VISUAL="nvim"
export TERM="xterm-256color"

source $ZSH/oh-my-zsh.sh

# ── Oh My Posh prompt ─────────────────────────
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/zen.toml)"

# ── Aliases ────────────────────────────────────
alias ls='eza -a --icons=always'
alias ll='eza -al --icons=always'
alias la='eza -a --icons=always'
alias lt='eza -a --tree --level=1 --icons=always'
alias grep='grep --color=auto'
alias vim='nvim'
alias v='nvim'
alias c='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias hyprconf='nvim ~/.config/hypr/hyprland.conf'
alias waybarconf='nvim ~/.config/waybar/config.jsonc'
alias zshconf='nvim ~/.zshrc'
alias dots='cd ~/anand-dots'
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'

# ── History ────────────────────────────────────
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

# ── Welcome screen (fastfetch) ─────────────────
fastfetch
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
