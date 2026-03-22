# ╔══════════════════════════════════════════════════════════════╗
# ║               anand-dots — ZSH Configuration                ║
# ║      Inspired by end-4/dots-hyprland, HyDE-Project, ML4W    ║
# ╚══════════════════════════════════════════════════════════════╝

# ── Skip for non-interactive shells ───────────────────────────
[[ $- != *i* ]] && return

# ─────────────────────────────────────────────────────────────
# ❰ OH MY ZSH ❱
# ─────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    colored-man-pages
    sudo
    archlinux
    copypath
    dirhistory
    extract
    command-not-found
)

source $ZSH/oh-my-zsh.sh

# ─────────────────────────────────────────────────────────────
# ❰ ENVIRONMENT ❱
# ─────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export TERM="xterm-256color"
export COLORTERM="truecolor"
export LESS="-R --use-color"

# ─────────────────────────────────────────────────────────────
# ❰ ZSH OPTIONS ❱
# ─────────────────────────────────────────────────────────────
setopt AUTO_CD              # cd without typing cd
setopt AUTO_PUSHD           # push visited dirs onto the stack
setopt PUSHD_IGNORE_DUPS    # no duplicate entries in stack
setopt PUSHD_SILENT         # no output after pushd/popd
setopt CORRECT              # spelling correction for commands
setopt EXTENDED_GLOB        # extended globbing patterns
setopt INTERACTIVE_COMMENTS # allow # comments in interactive mode
setopt COMPLETE_IN_WORD     # complete from cursor position
setopt ALWAYS_TO_END        # move cursor to end after completion
setopt NO_BEEP              # silence all bells

# ─────────────────────────────────────────────────────────────
# ❰ HISTORY ❱
# ─────────────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt EXTENDED_HISTORY          # save timestamps to history
setopt HIST_IGNORE_DUPS          # ignore consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS      # remove older duplicate entries
setopt HIST_IGNORE_SPACE         # ignore commands starting with space
setopt HIST_SAVE_NO_DUPS         # don't save duplicates
setopt HIST_EXPIRE_DUPS_FIRST    # expire duplicates first
setopt HIST_FIND_NO_DUPS         # no dupes in history search
setopt SHARE_HISTORY             # share history across sessions
setopt INC_APPEND_HISTORY        # write to history immediately

# ─────────────────────────────────────────────────────────────
# ❰ COMPLETION ❱
# ─────────────────────────────────────────────────────────────
# Rebuild completion cache only once per day
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*' group-name ''
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always

# ─────────────────────────────────────────────────────────────
# ❰ KEY BINDINGS ❱
# ─────────────────────────────────────────────────────────────
bindkey -e                            # emacs-style bindings
bindkey '^[[A'    history-substring-search-up   2>/dev/null || bindkey '^[[A' up-line-or-search
bindkey '^[[B'    history-substring-search-down 2>/dev/null || bindkey '^[[B' down-line-or-search
bindkey '^[[1;5C' forward-word        # Ctrl+Right → jump word
bindkey '^[[1;5D' backward-word       # Ctrl+Left  → jump word back
bindkey '^[[3~'   delete-char         # Del key
bindkey '^H'      backward-delete-word # Ctrl+Backspace → delete word

# ─────────────────────────────────────────────────────────────
# ❰ AUTOSUGGESTIONS  ❱
# ─────────────────────────────────────────────────────────────
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#6c7086'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
bindkey '^L' autosuggest-accept       # Ctrl+L → accept suggestion

# ─────────────────────────────────────────────────────────────
# ❰ SYNTAX HIGHLIGHTING (Catppuccin Mocha) ❱
# ─────────────────────────────────────────────────────────────
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#a6e3a1'          # green
ZSH_HIGHLIGHT_STYLES[alias]='fg=#a6e3a1'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#a6e3a1'
ZSH_HIGHLIGHT_STYLES[function]='fg=#a6e3a1'
ZSH_HIGHLIGHT_STYLES[path]='fg=#89b4fa'             # blue
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f38ba8'    # red
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#f9e2af' # yellow
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#f9e2af'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#6c7086'          # grey
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#fab387'         # peach
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#cba6f7' # mauve

# ─────────────────────────────────────────────────────────────
# ❰ LS → EZA ❱
# ─────────────────────────────────────────────────────────────
if command -v eza &>/dev/null; then
    alias ls='eza -a --icons=always --group-directories-first'
    alias ll='eza -al --icons=always --group-directories-first --git --header'
    alias la='eza -a --icons=always --group-directories-first'
    alias lt='eza -a --tree --level=2 --icons=always --group-directories-first'
    alias ltt='eza -a --tree --level=3 --icons=always --group-directories-first'
    alias l='eza -1 --icons=always'
    alias tree='eza --tree --icons=always --group-directories-first'
fi

# ─────────────────────────────────────────────────────────────
# ❰ CAT → BAT ❱
# ─────────────────────────────────────────────────────────────
if command -v bat &>/dev/null; then
    alias cat='bat --style=plain --paging=never'
    alias catp='bat'
    alias less='bat --paging=always'
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# ─────────────────────────────────────────────────────────────
# ❰ FZF — FUZZY FINDER ❱
# ─────────────────────────────────────────────────────────────
if command -v fzf &>/dev/null; then
    # Source fzf shell integration
    source /usr/share/fzf/key-bindings.zsh   2>/dev/null
    source /usr/share/fzf/completion.zsh     2>/dev/null

    # Catppuccin Mocha palette
    export FZF_DEFAULT_OPTS="
        --height=50% --layout=reverse --border=rounded
        --info=inline --cycle
        --color=bg+:#313244,bg:#1e1e2e,spinner:#f5c2e7,hl:#89b4fa
        --color=fg:#cdd6f4,header:#89b4fa,info:#cba6f7,pointer:#f5c2e7
        --color=marker:#a6e3a1,fg+:#cdd6f4,prompt:#cba6f7,hl+:#89b4fa
        --color=border:#45475a,label:#cdd6f4
        --prompt='  ' --pointer='❯' --marker='●'
    "

    # Use fd if available, else ripgrep, else find
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi

    # Ctrl+R → beautiful history search
    export FZF_CTRL_R_OPTS="
        --preview 'echo {}' --preview-window=down:3:wrap
        --bind 'ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'
        --header 'ctrl-y: copy to clipboard'
    "

    # Fuzzy kill process
    function fkill() {
        local pid
        pid=$(ps aux | fzf --header='[kill process]' | awk '{print $2}')
        [[ -n "$pid" ]] && kill -9 "$pid" && echo "→ killed $pid"
    }

    # Fuzzy cd (interactive directory jump)
    function fcd() {
        local dir
        dir=$(find "${1:-.}" -type d 2>/dev/null | fzf --preview 'eza --tree --level=2 --icons=always {}') &&
        cd "$dir"
    }

    # Fuzzy open file in nvim
    function fv() {
        local file
        file=$(fzf --preview 'bat --color=always --style=numbers --line-range=:100 {}' 2>/dev/null) &&
        [[ -n "$file" ]] && nvim "$file"
    }
fi

# ─────────────────────────────────────────────────────────────
# ❰ ZOXIDE — SMART CD ❱
# ─────────────────────────────────────────────────────────────
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh --cmd cd)"
fi

# ─────────────────────────────────────────────────────────────
# ❰ EDITOR ALIASES ❱
# ─────────────────────────────────────────────────────────────
alias vim='nvim'
alias vi='nvim'
alias v='nvim'
alias sv='sudo nvim'

# ─────────────────────────────────────────────────────────────
# ❰ NAVIGATION ❱
# ─────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias c='clear'
alias q='exit'
alias :q='exit'
alias cls='clear'

# ─────────────────────────────────────────────────────────────
# ❰ SYSTEM ❱
# ─────────────────────────────────────────────────────────────
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'
alias mkdir='mkdir -pv'
alias df='df -h'
alias du='du -h --max-depth=1'
alias free='free -h'
alias ps='ps auxf'
alias top='btop 2>/dev/null || htop 2>/dev/null || top'
alias rm='rm -I'                    # prompt before removing > 3 files

# ─────────────────────────────────────────────────────────────
# ❰ ARCH / PACMAN ❱
# ─────────────────────────────────────────────────────────────
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rns'
alias search='pacman -Ss'
alias pkglist='pacman -Qq | fzf --preview "pacman -Qil {}" --layout=reverse --bind "enter:execute(pacman -Qil {} | less)"'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null && echo "→ orphans removed" || echo "→ no orphans found"'
alias mirrors='sudo reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist && echo "→ mirrors updated"'

# ─────────────────────────────────────────────────────────────
# ❰ HYPRLAND / DOTS ❱
# ─────────────────────────────────────────────────────────────
alias hyprconf='nvim ~/.config/hypr/hyprland.conf'
alias hyprkeys='nvim ~/.config/hypr/keybindings.conf'
alias hyprtheme='nvim ~/.config/hypr/theme.conf'
alias waybarconf='nvim ~/.config/waybar/config.jsonc'
alias waybarstyle='nvim ~/.config/waybar/style.css'
alias kittyconf='nvim ~/.config/kitty/kitty.conf'
alias zshconf='nvim ~/.zshrc'
alias dots='cd ~/anand-dots'
alias reload='source ~/.zshrc && echo "→ zshrc reloaded"'
alias nf='fastfetch'

# ─────────────────────────────────────────────────────────────
# ❰ GIT ❱
# ─────────────────────────────────────────────────────────────
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -m'
alias gca='git commit --amend --no-edit'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate --all'
alias gp='git push'
alias gpu='git push -u origin HEAD'
alias gpl='git pull'
alias gs='git status -sb'
alias gst='git stash'
alias gstp='git stash pop'
alias grl='git reflog'

# ─────────────────────────────────────────────────────────────
# ❰ FUNCTIONS ❱
# ─────────────────────────────────────────────────────────────

# cd then ls
function cl() {
    cd "$@" && ls
}

# mkdir then cd
function mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Extract any archive
function extract() {
    if [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)  tar xjf "$1"   ;;
            *.tar.gz)   tar xzf "$1"   ;;
            *.tar.xz)   tar xJf "$1"   ;;
            *.tar.zst)  tar --zstd -xf "$1" ;;
            *.bz2)      bunzip2 "$1"   ;;
            *.gz)       gunzip  "$1"   ;;
            *.tar)      tar xf  "$1"   ;;
            *.tbz2)     tar xjf "$1"   ;;
            *.tgz)      tar xzf "$1"   ;;
            *.zip)      unzip   "$1"   ;;
            *.Z)        uncompress "$1";;
            *.7z)       7z x    "$1"   ;;
            *.zst)      unzstd  "$1"   ;;
            *.rar)      unrar x "$1"   ;;
            *)          echo "'$1' — unknown archive format" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Copy file content to clipboard
function yank() {
    [[ -f "$1" ]] && cat "$1" | wl-copy && echo "→ '$1' copied to clipboard"
}

# Quick note to clipboard
function note() {
    echo "$*" | wl-copy && echo "→ copied to clipboard"
}

# Show PATH entries one per line
function path() {
    echo "${PATH//:/$'\n'}"
}

# Reload Waybar
function waybar-reload() {
    pkill -x waybar; waybar &disown
    echo "→ waybar restarted"
}

# Display colors table (256 colors)
function colortest() {
    for i in {0..255}; do
        printf "\e[38;5;${i}m%3d\e[0m " "$i"
        [[ $(( (i+1) % 16 )) -eq 0 ]] && echo
    done
}

# Show directory sizes, sorted
function dusort() {
    du -h --max-depth=1 "${1:-.}" | sort -rh | head -20
}

# ─────────────────────────────────────────────────────────────
# ❰ OH MY POSH PROMPT ❱
# ─────────────────────────────────────────────────────────────
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh/zen.toml)"

# ─────────────────────────────────────────────────────────────
# ❰ WELCOME ❱
# ─────────────────────────────────────────────────────────────
fastfetch
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
w