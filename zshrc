# export DOTDIR="$HOME/.config"
export DOTDIR="$HOME/Code/dotfiles-chezmoi"
export ZSH_DIR="$DOTDIR/.config/zsh"
export ZSH_PLUGIN_DIR="$ZSH_DIR/plugins"

export _VERBOSE=1 # 1 or 0

. $ZSH_DIR/init-functions.zsh

files=(
  kill-port
  aliases
  homebrew
)
file-load $files

#------------------------- PLUGINS -----------------------------
plugins=(
  rupa/z
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-history-substring-search
)
plugin-load $plugins

