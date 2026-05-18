# Login shell environment — keep minimal.

# Homebrew (Mac arm64, Mac x86, Linuxbrew — first one that exists wins)
for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x $brew_bin ]]; then
    eval "$($brew_bin shellenv)"
    break
  fi
done

# bat theme
export BAT_THEME="gruvbox-dark"

# Local login overrides (gitignored)
[[ -f $HOME/.zprofile.local ]] && source "$HOME/.zprofile.local"
