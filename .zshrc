#───────────────────────────────────────────────────────────────────────────────
# .zshrc — modern, minimal, cross-platform
# Structure: env → OS detect → zinit → plugins → tools → keys → aliases → local
#───────────────────────────────────────────────────────────────────────────────

# ── Early environment ─────────────────────────────────────────────────────────
export LANG=en_US.UTF-8

# DOTDIR points at wherever you cloned this repo. Default: ~/dotfiles.
# Override in ~/.zshrc.local if you cloned somewhere else.
export DOTDIR="${DOTDIR:-$HOME/dotfiles}"

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
  export VISUAL='vim'
else
  export EDITOR='nvim'
  export VISUAL='nvim'
fi

# ── OS detection ──────────────────────────────────────────────────────────────
case "$OSTYPE" in
  darwin*) IS_MAC=1   ;;
  linux*)  IS_LINUX=1 ;;
esac

# ── PATH (guarded; prepend in reverse priority order) ─────────────────────────
typeset -U path
[[ -d $HOME/.local/bin ]]  && path=("$HOME/.local/bin" $path)
[[ -d $HOME/bin ]]         && path=("$HOME/bin" $path)
[[ -d $HOME/.cargo/bin ]]  && path=("$HOME/.cargo/bin" $path)
[[ -d $HOME/.bun/bin ]]    && path=("$HOME/.bun/bin" $path)
export BUN_INSTALL="$HOME/.bun"

# ── Zinit bootstrap ───────────────────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d $ZINIT_HOME ]]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"

# ── Oh-My-Zsh snippets (cherry-picked, not the whole framework) ───────────────
zinit snippet OMZL::git.zsh
zinit snippet OMZL::directories.zsh
zinit snippet OMZL::theme-and-appearance.zsh
zinit snippet OMZL::async_prompt.zsh
zinit snippet OMZP::git
zinit snippet OMZP::direnv

# ── eza plugin (must be configured BEFORE loading) ────────────────────────────
zstyle ':omz:plugins:eza' 'dirs-first' yes
zstyle ':omz:plugins:eza' 'git-status'  yes
zstyle ':omz:plugins:eza' 'header'      yes
zstyle ':omz:plugins:eza' 'icons'       yes
zinit snippet OMZP::eza

# ── Interactive plugins (deferred for fast startup) ───────────────────────────
zinit wait lucid for \
  atinit"zicompinit; zicdreplay" \
    zdharma-continuum/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
  blockf \
    zsh-users/zsh-completions \
  Aloxaf/fzf-tab

# ── History ───────────────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_dups hist_ignore_space hist_verify

# ── Tool inits (order matters: starship → fnm → zoxide → atuin last) ──────────
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v fnm      >/dev/null && eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"
command -v atuin    >/dev/null && eval "$(atuin init zsh)"

# Terraform completion (Mac brew path; falls back gracefully on Linux)
if command -v terraform >/dev/null; then
  autoload -U +X bashcompinit && bashcompinit
  complete -o nospace -C "$(command -v terraform)" terraform
fi

# Bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# 1Password CLI plugin shim — transparently injects credentials into
# wrapped CLIs (heroku, sentry-cli, gh, …). Init plugins with
# `./setup-op-plugins.sh` from the dotfiles repo.
[[ -f "$HOME/.config/op/plugins.sh" ]] && source "$HOME/.config/op/plugins.sh"

# ── Mac-only ──────────────────────────────────────────────────────────────────
if (( ${+IS_MAC} )); then
  # 1Password SSH agent
  export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  alias pbc='pbcopy'
  alias pbp='pbpaste'
fi

# ── Linux-only ────────────────────────────────────────────────────────────────
if (( ${+IS_LINUX} )); then
  command -v xclip >/dev/null && alias pbc='xclip -selection clipboard'
  command -v xclip >/dev/null && alias pbp='xclip -selection clipboard -o'
fi

# ── Aliases (minimal core; add to ~/.zshrc.local as you rediscover needs) ─────
alias cdot='cd $DOTDIR'
alias zrefresh='exec zsh'
alias reload='source ~/.zshrc'

alias vim='nvim'
alias v='nvim'

alias gco='git checkout'
alias gst='git status'
alias gd='git diff'
alias gp='git pull'
alias gpu='git push'

alias dc='docker compose'

alias python='python3'
alias pip='pip3'

alias ls='eza --git --icons --group-directories-first'
alias ll='eza -l --git --icons --group-directories-first'
alias la='eza -la --git --icons --group-directories-first'
alias lt='eza --tree --level=2 --git-ignore'

# Kill the process listening on a given port:  kp 3000
kp() {
  if [[ -z "$1" ]]; then
    echo "usage: kp <port>" >&2
    return 1
  fi
  local pid
  pid=$(lsof -ti tcp:"$1")
  [[ -z "$pid" ]] && { echo "no process on port $1"; return 1; }
  kill -9 "$pid" && echo "killed $pid on port $1"
}

# ── Local overrides (gitignored; private secrets, machine-specific paths) ─────
[[ -f $HOME/.zshrc.local ]] && source "$HOME/.zshrc.local"
