# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation (installed by dotfiles/install.sh).
export ZSH="$HOME/.oh-my-zsh"

# Starship renders the prompt, so disable the OMZ theme to avoid double rendering.
ZSH_THEME=""

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Auto-update OMZ without prompting, weekly.
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 13

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git
  fzf
  zsh-autosuggestions
  zsh-syntax-highlighting
  )

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# EDITOR is set below (nvim).

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export EDITOR='nvim'
export VISUAL='nvim'
export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/.local/share/pnpm"
# Dedupe PATH (was appending duplicates on every reload).
typeset -U path PATH
path=(
  "$PNPM_HOME"
  "$BUN_INSTALL/bin"
  "$HOME/bin"
  "$HOME/.local/bin"
  /usr/local/go/bin
  /usr/local/bin
  $path
)
export PATH
# WSL glue (wslu isn't packaged on Fedora — use interop directly)
if grep -qi microsoft /proc/version 2>/dev/null; then
  export BROWSER="explorer.exe"
  # open <url|path> in Windows (like macOS `open`); bare `open` opens cwd in Explorer
  open() {
    if [ $# -eq 0 ]; then explorer.exe .; return; fi
    for target in "$@"; do
      case "$target" in
        http*|mailto:*) explorer.exe "$target" ;;
        *) explorer.exe "$(wslpath -w "$target" 2>/dev/null || echo "$target")" ;;
      esac
    done
  }
  alias pbcopy='clip.exe'
  alias pbpaste='powershell.exe -NoProfile -NonInteractive -Command Get-Clipboard'
  # Re-register the .exe handler if interop dies (symptom: "exec format error").
  # Root cause is /init losing its binfmt_misc entry; this restores it live.
  wsl-fix-interop() {
    if [ ! -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
      sudo sh -c 'echo ":WSLInterop:M::MZ::/init:PF" > /proc/sys/fs/binfmt_misc/register'
    fi
    powershell.exe -NoProfile -NonInteractive -Command "Write-Output interop-ok"
  }
fi

# Modern CLI (dnf: fzf zoxide eza bat fd-find) — guarded so this file works anywhere
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
[ -f /usr/share/fzf/shell/key-bindings.zsh ] && source /usr/share/fzf/shell/key-bindings.zsh
command -v eza >/dev/null && {
  alias ls='eza --group-directories-first'
  alias ll='eza -lh --group-directories-first --git'
  alias la='eza -lah --group-directories-first --git'
  alias lt='eza --tree --level=2'
}
command -v bat >/dev/null && alias cat='bat --paging=never'
command -v lazygit >/dev/null && alias lg='lazygit'

# History
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
