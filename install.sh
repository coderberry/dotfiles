#!/usr/bin/env bash
#
# Minimal dotfiles bootstrap.
# Installs GNU Stow if missing, then symlinks everything in this repo into $HOME.
# Zinit, Starship, and friends bootstrap themselves on first shell load.
#
set -euo pipefail

cd "$(dirname "$0")"

# ── 1. Ensure Stow is installed ───────────────────────────────────────────────
if ! command -v stow >/dev/null 2>&1; then
  echo "→ Installing GNU Stow…"
  if [[ "$OSTYPE" == darwin* ]]; then
    command -v brew >/dev/null 2>&1 || {
      echo "Homebrew is required on macOS. Install from https://brew.sh"; exit 1;
    }
    brew install stow
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y stow
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y stow
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm stow
  else
    echo "Install GNU Stow manually for your platform, then re-run."; exit 1
  fi
fi

# ── 2. Back up any pre-existing real files that Stow would clobber ────────────
ts=$(date +%Y%m%d-%H%M%S)
for f in .zshrc .zprofile .gitconfig .gitignore_global; do
  target="$HOME/$f"
  if [[ -e $target && ! -L $target ]]; then
    echo "→ Backing up $target → $target.bak.$ts"
    mv "$target" "$target.bak.$ts"
  fi
done

# ── 3. Stow ───────────────────────────────────────────────────────────────────
echo "→ Stowing into $HOME"
stow --target="$HOME" --verbose=1 --restow .

cat <<EOF

✓ Done. Next steps:

  1. Open a new shell — Zinit will bootstrap itself on first run.
  2. Install runtime deps (per platform): starship atuin zoxide eza fnm fzf
     macOS:  brew install starship atuin zoxide eza fnm fzf
     Linux:  see brew.txt for the full list
  3. (Mac) Open Karabiner-Elements and import karabiner/capslock_to_tilde.json
     under Complex Modifications if you want Caps Lock → ~.
  4. Drop any private/machine-specific config into ~/.zshrc.local
     (gitignored; sourced at end of .zshrc).
EOF
