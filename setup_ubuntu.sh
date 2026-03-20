#!/bin/bash
# Premium terminal setup for Ubuntu 24.04
# Run: chmod +x setup_ubuntu.sh && ./setup_ubuntu.sh

set -e

echo ""
echo "── Updating packages ───────────────────────────────────"
sudo apt update -qq

echo ""
echo "── 1/8  Zsh ────────────────────────────────────────────"
if ! command -v zsh &>/dev/null; then
  sudo apt install -y zsh
  chsh -s "$(which zsh)"
  echo "✓ Zsh installed — will be default shell after logout/login"
else
  echo "✓ Already installed"
fi

echo ""
echo "── 2/8  Git + curl + build tools ──────────────────────"
sudo apt install -y git curl wget unzip fontconfig
echo "✓ Done"

echo ""
echo "── 3/8  Starship (prompt) ──────────────────────────────"
curl -sS https://starship.rs/install.sh | sh -s -- --yes
echo "✓ Starship installed"

echo ""
echo "── 4/8  eza (modern ls) ────────────────────────────────"
sudo apt install -y gpg
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
  | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
  | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update -qq && sudo apt install -y eza
echo "✓ eza installed"

echo ""
echo "── 5/8  bat (modern cat) ───────────────────────────────"
sudo apt install -y bat
# Ubuntu installs it as 'batcat' to avoid conflict
mkdir -p ~/.local/bin
ln -sf /usr/bin/batcat ~/.local/bin/bat
echo "✓ bat installed (symlinked as 'bat')"

echo ""
echo "── 6/8  fzf (fuzzy finder) ─────────────────────────────"
if [ -d ~/.fzf ]; then
  # Ensure zsh integration is generated for git-clone install
  ~/.fzf/install --all --no-bash --no-fish --no-update-rc 2>/dev/null || true
  echo "✓ Already installed (via git clone) — zsh keybindings generated"
else
  sudo apt install -y fzf
  echo "✓ fzf installed — ctrl+r: history search, ctrl+t: file search"
fi

echo ""
echo "── 7/8  zsh plugins ────────────────────────────────────"
sudo apt install -y zsh-autosuggestions zsh-syntax-highlighting
echo "✓ Plugins installed"

echo ""
echo "── 8/8  tree + broot ───────────────────────────────────"
sudo apt install -y tree
# broot — download latest binary
BROOT_URL=$(curl -s https://api.github.com/repos/Canop/broot/releases/latest \
  | grep '"browser_download_url"' \
  | grep 'x86_64-unknown-linux-musl' \
  | head -1 \
  | cut -d'"' -f4)
if [ -n "$BROOT_URL" ]; then
  curl -sL "$BROOT_URL" -o /tmp/broot
  chmod +x /tmp/broot
  sudo mv /tmp/broot /usr/local/bin/broot
  broot --install
  echo "✓ tree + broot installed"
else
  echo "⚠ broot: could not find download URL, skipping (install manually later)"
  echo "✓ tree installed"
fi

echo ""
echo "── Nerd Font (JetBrainsMono) ───────────────────────────"
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" \
  -o /tmp/JetBrainsMono.zip
unzip -qo /tmp/JetBrainsMono.zip -d "$FONT_DIR/JetBrainsMono"
fc-cache -fq
echo "✓ JetBrainsMono Nerd Font installed"

echo ""
echo "── Writing ~/.zshrc ────────────────────────────────────"
# Back up existing .zshrc if present
[ -f ~/.zshrc ] && cp ~/.zshrc ~/.zshrc.bak && echo "  (backed up existing .zshrc to .zshrc.bak)"

cat > ~/.zshrc << 'EOF'
# ─────────────────────────────────────────────────────────────
#  PATH
# ─────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

# ─────────────────────────────────────────────────────────────
#  HISTORY
# ─────────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_VERIFY SHARE_HISTORY EXTENDED_HISTORY

# ─────────────────────────────────────────────────────────────
#  COMPLETION
# ─────────────────────────────────────────────────────────────
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
setopt AUTO_CD CORRECT

# ─────────────────────────────────────────────────────────────
#  COLORS
# ─────────────────────────────────────────────────────────────
export CLICOLOR=1
alias grep='grep --color=auto'

# ─────────────────────────────────────────────────────────────
#  KEY BINDINGS
# ─────────────────────────────────────────────────────────────
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# ─────────────────────────────────────────────────────────────
#  ALIASES — navigation
# ─────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd ~'
alias -- -='cd -'
alias reload='source ~/.zshrc && echo "  zshrc reloaded"'
alias path='echo $PATH | tr ":" "\n"'

# ─────────────────────────────────────────────────────────────
#  ALIASES — git
# ─────────────────────────────────────────────────────────────
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate --color'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# ─────────────────────────────────────────────────────────────
#  eza — modern ls
# ─────────────────────────────────────────────────────────────
alias ls='eza --icons'
alias ll='eza -lh --icons --git'
alias la='eza -lah --icons --git'
alias lt='eza --tree --icons --level=2'

# ─────────────────────────────────────────────────────────────
#  bat — modern cat
# ─────────────────────────────────────────────────────────────
alias cat='bat --paging=never'
export BAT_THEME="TwoDark"

# ─────────────────────────────────────────────────────────────
#  tree
# ─────────────────────────────────────────────────────────────
alias tree='tree -C'
alias t2='tree -L 2'
alias t3='tree -L 3'
alias td='tree -d'

# ─────────────────────────────────────────────────────────────
#  FUNCTIONS
# ─────────────────────────────────────────────────────────────
mkcd() { mkdir -p "$1" && cd "$1"; }
f() { find . -iname "*$1*" 2>/dev/null; }
extract() {
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;; *.tar.gz)  tar xzf "$1" ;;
    *.tar.xz)  tar xJf "$1" ;; *.bz2)     bunzip2 "$1" ;;
    *.gz)      gunzip "$1"  ;; *.tar)      tar xf "$1"  ;;
    *.zip)     unzip "$1"   ;; *.7z)       7z x "$1"    ;;
    *) echo "Unknown archive: $1" ;;
  esac
}

# ─────────────────────────────────────────────────────────────
#  fzf — fuzzy finder (ctrl+r: history, ctrl+t: files)
# ─────────────────────────────────────────────────────────────
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --color=dark"

# ─────────────────────────────────────────────────────────────
#  broot — interactive tree navigator (type 'br')
# ─────────────────────────────────────────────────────────────
[[ -f ~/.config/broot/launcher/bash/br ]] && \
  source ~/.config/broot/launcher/bash/br

# ─────────────────────────────────────────────────────────────
#  zsh-autosuggestions — ghost-text from history (→ to accept)
# ─────────────────────────────────────────────────────────────
[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=240"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ─────────────────────────────────────────────────────────────
#  zsh-syntax-highlighting — must be sourced LAST among plugins
# ─────────────────────────────────────────────────────────────
[[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ─────────────────────────────────────────────────────────────
#  ROS 2 Jazzy
# ─────────────────────────────────────────────────────────────
[ -f /opt/ros/jazzy/setup.zsh ] && source /opt/ros/jazzy/setup.zsh

# export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
# export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST
# export ROS_DOMAIN_ID=1
# export CYCLONEDDS_URI=/home/fanyang1/cyclonedds_ros2.xml

# ─────────────────────────────────────────────────────────────
#  Starship prompt (must be last, before conda)
# ─────────────────────────────────────────────────────────────
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi
EOF

echo ""
echo "── Copying Starship config ─────────────────────────────"
mkdir -p ~/.config
cat > ~/.config/starship.toml << 'STARSHIP_EOF'
"$schema" = 'https://starship.rs/config-schema.json'

format = """
[╭─](bold 240) $directory$git_branch$git_status$python$nodejs$rust $time
[╰─❯](bold green) """

right_format = "$cmd_duration$status"

[directory]
style = "bold cyan"
truncation_length = 4
truncate_to_repo = true

[git_branch]
symbol = " "
style = "bold magenta"
format = "[$symbol$branch]($style) "

[git_status]
style = "bold red"
format = '([\[$all_status$ahead_behind\]]($style) )'
conflicted = "⚡"
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
modified = "!${count}"
untracked = "?${count}"
staged = "+${count}"
deleted = "✘${count}"

[time]
disabled = false
format = "[$time]($style)"
style = "bold 240"
time_format = "%H:%M"

[cmd_duration]
min_time = 2_000
format = "[ $duration](bold yellow)"

[status]
disabled = false
format = "[$symbol$status]($style) "
symbol = "✘ "
style = "bold red"
not_executable_symbol = "🔒 "
not_found_symbol = "🔍 "

[python]
symbol = " "
style = "bold yellow"
format = '[$symbol$pyenv_prefix($version)(\($virtualenv\))]($style) '

[nodejs]
symbol = " "
style = "bold green"
format = "[$symbol($version)]($style) "

[rust]
symbol = " "
style = "bold red"
format = "[$symbol($version)]($style) "
STARSHIP_EOF
echo "✓ Starship config written"

echo ""
echo "── Conda (init for zsh) ──────────────────────────────────"
if [ -d "$HOME/anaconda3" ]; then
  # Append conda init block directly (avoids conda init zsh clobbering .zshrc)
  cat >> ~/.zshrc << 'CONDA_EOF'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$("$HOME/anaconda3/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
CONDA_EOF
  echo "✓ Conda initialized for zsh"
else
  echo "⚠ anaconda3 not found at ~/anaconda3, skipping conda init"
fi

echo ""
echo "─────────────────────────────────────────────────────────"
echo "  Done!"
echo ""
echo "  Next steps:"
echo "  1. Log out and back in (or run: zsh) to use Zsh"
echo "  2. Set terminal font to: JetBrainsMono Nerd Font"
echo "  3. Run: source ~/.zshrc"
echo "─────────────────────────────────────────────────────────"
