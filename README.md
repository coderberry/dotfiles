# dotfiles

Minimal, cross-platform (macOS-primary, Linux-aware) dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's here

| File / dir                  | What it does                                                              |
| --------------------------- | ------------------------------------------------------------------------- |
| `.zshrc`                    | Zinit + cherry-picked OMZ snippets, modern CLI tools, shell functions.    |
| `.aliases`                  | Every shell alias, grouped by domain. Sourced by `.zshrc`.                |
| `.zprofile`                 | Login-only env: Homebrew shellenv, `BAT_THEME`.                           |
| `.gitconfig`                | Sane defaults + aliases. Identity lives in `~/.gitconfig.local`.          |
| `.gitconfig.local.example`  | Copy to `~/.gitconfig.local` and fill in your name/email.                 |
| `.gitignore_global`         | Global git ignore (referenced by `.gitconfig`).                           |
| `.config/starship.toml`     | Prompt config (disables noisy modules; defaults otherwise).               |
| `.config/ghostty/`          | Ghostty terminal — JetBrains Mono Nerd Font, Gruvbox, Mac option=alt.     |
| `.config/gh/`               | GitHub CLI config + aliases.                                              |
| `.config/nvim/`             | Minimal LazyVim bootstrap (no custom plugin overrides).                   |
| `karabiner/`                | Caps Lock → `~` Karabiner rule (Mac; import manually, not stowed).        |
| `templates/`                | Secret-bearing files (`.npmrc`, `.netrc`, …) rendered via `op inject`.    |
| `setup-op-plugins.sh`       | Initializes `op plugin` for `heroku`, `sentry-cli`, `gh`.                 |
| `Brewfile.mac`              | Curated `brew bundle` file for macOS (with opt-in extras at the bottom).  |
| `Brewfile.linux`            | Linuxbrew formulae for the modern CLI stack.                              |
| `install.sh`                | macOS-ready: installs Stow, backs up conflicts, runs `stow .`.            |
| `install-linux.sh`          | Linux bootstrap: apt prereqs → Linuxbrew → `brew bundle` → `stow .`.      |

## Install

Clone wherever you like — these instructions assume `~/dotfiles`. If you put it somewhere else, set `DOTDIR` in `~/.zshrc.local`.

### macOS

```bash
git clone https://github.com/<your-fork>/dotfiles ~/dotfiles
cd ~/dotfiles

# 1. Set up your identity (not committed)
cp .gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local

# 2. Symlinks (installs Stow if needed)
./install.sh

# 3. Install the CLI tools
brew bundle --file=Brewfile.mac
```

### Linux (Ubuntu/Debian-focused; falls back for Fedora/Arch)

```bash
git clone https://github.com/<your-fork>/dotfiles ~/dotfiles
cd ~/dotfiles

# 1. Set up your identity (not committed)
cp .gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local

# 2. One command: apt prereqs → Linuxbrew → brew bundle → stow → chsh to zsh
./install-linux.sh
```

Open a new shell. Zinit bootstraps itself on first launch (clones to `~/.local/share/zinit/zinit.git`), then loads plugins.

## Architecture

- **Stow** for symlinks. Add a file to the repo, run `stow .`, done.
- **Zinit** for plugin loading. Cherry-picks the handful of OMZ snippets that matter; deferred plugin loading keeps shell startup fast.
- **Starship** for the prompt. Minimal override on top of Starship defaults.
- **Atuin / zoxide / eza / fzf-tab / fnm** as the modern CLI baseline.
- **Two shell files, not a `.zsh.d/` tree** — `.zshrc` for env, plugins, tools, and functions; `.aliases` for aliases. Still easy to scan.
- **OS detection** via `$OSTYPE` gates Mac-only bits (1Password SSH socket, `pbcopy`). `.aliases` is sourced *after* detection, so it can gate on `$IS_MAC` / `$IS_LINUX` too.

### Where a given thing belongs

| Kind of config            | Goes in                           |
| ------------------------- | --------------------------------- |
| Alias                     | `.aliases`                        |
| Short shell function      | `.zshrc` (Functions section)      |
| Longer shell function     | `.zsh/functions/`                 |
| SSH host                  | `~/.ssh/config` as a `Host` entry |
| Anything machine-specific | `~/.zshrc.local`                  |

SSH hosts are deliberately **not** aliases. A `Host` entry works for `ssh`, `scp`, `rsync`, and git remotes alike, and keeps addresses out of this repo:

```
Host myserver
  HostName 203.0.113.10
  User me
  Port 2222
```

## Local overrides (private, not committed)

Three escape hatches for machine-specific config. All are gitignored, and since Stow symlinks them from this repo into `$HOME`, the real files live here — keeping them out of git matters:

| File                  | Sourced from        | Use for                                                  |
| --------------------- | ------------------- | -------------------------------------------------------- |
| `~/.zshrc.local`      | end of `.zshrc`     | Per-machine aliases, secrets, project-specific paths.    |
| `~/.zprofile.local`   | end of `.zprofile`  | Login-only env (e.g. `JAVA_HOME` on a work machine).     |
| `~/.gitconfig.local`  | `.gitconfig`        | Your identity, signing keys, work-vs-personal includes.  |

## 1Password SSH agent (macOS)

`.zshrc` exports `SSH_AUTH_SOCK` to the 1Password agent socket on macOS. SSH keys live in 1Password; nothing is on disk. To enable in 1Password: **Settings → Developer → Use the SSH agent**.

## Secrets — hybrid 1Password integration

Two mechanisms work together so no API tokens ever land in the repo:

1. **`op plugin`** wraps supported CLIs (`heroku`, `sentry-cli`, `gh`). Secrets are injected into the CLI's environment only at invocation time. The shim is sourced from `.zshrc` so wrapped CLIs work transparently in every shell.
2. **`op inject` + [`templates/`](./templates/)** renders files for tools that aren't in `op plugin list` (npm, bun, the git ↔ `.netrc` integration). Templates reference items in a dedicated **`Dotfiles`** 1Password vault.

```bash
brew install 1password-cli
op signin

# Initialize op plugin shims (heroku, sentry-cli, gh)
./setup-op-plugins.sh

# Render templates for non-plugin tools (.npmrc, .bunfig.toml, .netrc)
cd templates && ./render.sh
```

See [templates/README.md](./templates/README.md) for the full pattern and the one-time `Dotfiles` vault setup.

## Karabiner-Elements (macOS)

`karabiner/capslock_to_tilde.json` is **not** stowed — it would clobber your `karabiner.json`. Open Karabiner-Elements → Complex Modifications → Add rule → import the JSON manually.

## Why no…

- **tmux** — Ghostty splits/tabs cover the need.
- **Mass font install** — `Brewfile.mac` ships two Nerd Fonts (JetBrains Mono, Meslo). Add more by uncommenting the optional section.
- **VS Code settings** — VS Code has built-in Settings Sync.
- **Oh My Zsh** — Zinit + a handful of OMZ snippets gives the same niceties with ~10× faster startup.

## License

[MIT](./LICENSE) — feel free to fork, adapt, and reuse.

---

Inspired by [Gordon Beeming's dotfiles setup](https://gordonbeeming.com/blog/2026-03-10/my-dotfiles-setup-how-i-manage-my-dev-environment), [his Claude-driven terminal migration](https://gordonbeeming.com/blog/2026-03-06/i-let-claude-migrate-my-entire-terminal-setup), and [Wicksipedia's modern zsh setup](https://wicksipedia.com/blog/modern-zsh-setup/).
