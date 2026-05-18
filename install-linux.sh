#!/usr/bin/env bash
#
# Linux bootstrap (Ubuntu/Debian-focused, falls back to a hint for other distros).
#
# Steps:
#   1. Install OS-level prerequisites via apt (build tools, curl, zsh, git, …).
#   2. Install Linuxbrew if missing, wire it into the current shell.
#   3. `brew bundle --file=Brewfile.linux`.
#   4. Hand off to install.sh for the Stow symlinks.
#
# Idempotent — safe to re-run.
#
set -euo pipefail

cd "$(dirname "$0")"

# ── 0. Sanity ─────────────────────────────────────────────────────────────────
if [[ "$OSTYPE" != linux* ]]; then
  echo "This script is for Linux. On macOS run ./install.sh + brew bundle --file=Brewfile.mac" >&2
  exit 1
fi

# ── 1. OS-level prerequisites ─────────────────────────────────────────────────
if command -v apt-get >/dev/null 2>&1; then
  echo "→ Installing apt prerequisites…"
  sudo apt-get update
  sudo apt-get install -y \
    build-essential \
    curl \
    file \
    git \
    procps \
    zsh \
    ca-certificates \
    fonts-jetbrains-mono
elif command -v dnf >/dev/null 2>&1; then
  echo "→ Installing dnf prerequisites…"
  sudo dnf install -y \
    @development-tools \
    procps-ng \
    curl \
    file \
    git \
    zsh \
    ca-certificates
elif command -v pacman >/dev/null 2>&1; then
  echo "→ Installing pacman prerequisites…"
  sudo pacman -S --noconfirm --needed base-devel curl file git zsh ca-certificates
else
  echo "⚠ Unknown distro — install build tools + curl + git + zsh manually, then re-run."
  exit 1
fi

# ── 2. Linuxbrew ──────────────────────────────────────────────────────────────
if ! command -v brew >/dev/null 2>&1; then
  echo "→ Installing Linuxbrew (Homebrew on Linux)…"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make brew available in *this* shell session
if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
  eval "$($HOME/.linuxbrew/bin/brew shellenv)"
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "✗ brew not found after install. Check the Homebrew installer output above." >&2
  exit 1
fi

# ── 3. Brewfile.linux ─────────────────────────────────────────────────────────
echo "→ Running brew bundle (Brewfile.linux)…"
brew bundle --file=Brewfile.linux

# ── 4. Stow symlinks ──────────────────────────────────────────────────────────
echo "→ Stowing dotfiles into \$HOME…"
./install.sh

# ── 5. zsh as default shell ───────────────────────────────────────────────────
zsh_path="$(command -v zsh)"
if [[ "${SHELL:-}" != "$zsh_path" ]]; then
  echo "→ Setting zsh as your default shell"
  echo "  (you'll be prompted for your password; or run manually: chsh -s $zsh_path)"
  chsh -s "$zsh_path" || echo "  ⚠ chsh failed — set the shell manually later."
fi

cat <<EOF

✓ Linux setup complete.

Next:
  1. Log out and back in (or start a new shell) — zsh will load and
     Zinit will bootstrap itself on first run.
  2. (Optional) Install starship/atuin/zoxide/eza/fnm via Brewfile.linux
     are already done. Run \`atuin login\` if you want sync across machines.
  3. Drop machine-specific config into ~/.zshrc.local (gitignored;
     sourced at the end of .zshrc).
EOF
