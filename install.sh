#!/usr/bin/env bash
# Dotfiles installer — run once per machine: ./install.sh
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Oh My Zsh (not vendored — cloned to ~/.oh-my-zsh)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Cloning oh-my-zsh to ~/.oh-my-zsh..."
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  if [ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]; then
    echo "Cloning $plugin..."
    git clone --depth=1 "https://github.com/zsh-users/$plugin.git" "$ZSH_CUSTOM/plugins/$plugin"
  fi
done

# 2. Symlinks (idempotent)
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "Backing up existing $dst to $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -sfn "$src" "$dst"
  echo "linked $dst -> $src"
}
link "$DOTFILES/.zshrc" "$HOME/.zshrc"
link "$DOTFILES/.tmux.conf" "$HOME/.tmux.conf"
link "$DOTFILES/.gitconfig" "$HOME/.gitconfig"
link "$DOTFILES/.config/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/.config/nvim" "$HOME/.config/nvim"
link "$DOTFILES/.config/mc" "$HOME/.config/mc"
link "$DOTFILES/.config/superfile" "$HOME/.config/superfile"

echo "Done. Restart your shell (or: exec zsh -l)."
