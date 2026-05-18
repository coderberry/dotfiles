# Templates

Secret-bearing files that can't live in the repo directly. The dotfiles use a **hybrid pattern** for secret management:

| Mechanism | Use when | Examples |
|---|---|---|
| **`op plugin`** (1Password CLI shim) | The tool's a CLI in [`op plugin list`](https://developer.1password.com/docs/cli/shell-plugins/) | `heroku`, `sentry-cli`, `gh` — handled by `setup-op-plugins.sh` at the repo root |
| **`op inject` + this directory** | The tool reads a config file directly and isn't in the plugin list | `npm`/`pnpm`/`yarn` reading `~/.npmrc`, `bun` reading `~/.bunfig.toml`, `git` reading `~/.netrc` |

**Tradeoff:** `op plugin` is more secure (secrets only exist in the env of one invocation, biometric prompt with caching) but only works for supported CLIs. `op inject` writes plaintext files to disk (mode `0600`) — second-best, but covers everything else.

All `op://` references point at a single **`Dotfiles`** 1Password vault.

## One-time vault setup

Create a vault named `Dotfiles` (sidebar → account → New Vault, or via CLI: `op vault create Dotfiles`). Then create these items — only the ones whose templates you'll actually render are needed:

| Item title | Type | Fields | Used by |
|---|---|---|---|
| `GitHub PAT - npm packages` | API Credential | `credential` = GH PAT with `read:packages` (+ `write:packages` if you publish) | `.npmrc`, `.bunfig.toml` |
| `npmjs.com token` | API Credential | `credential` = npmjs.org auth token | `.npmrc` |
| `Heroku CLI` | Login | `username` = Heroku email, `password` = Heroku API key | `.netrc` (for `git push heroku`; the `heroku` CLI itself uses `op plugin`) |

CLI version:

```bash
op vault create Dotfiles
op item create --vault Dotfiles --category 'API Credential' \
  --title 'GitHub PAT - npm packages' credential='<paste PAT>'
op item create --vault Dotfiles --category 'API Credential' \
  --title 'npmjs.com token' credential='<paste npm token>'
op item create --vault Dotfiles --category Login \
  --title 'Heroku CLI' username='you@example.com' password='<paste Heroku API key>'
```

(Sentry CLI, Heroku CLI, gh — these are handled by `op plugin init` in `setup-op-plugins.sh`, not items in this vault.)

## How rendering works

1. **Sign in to 1Password CLI:** `op signin`
2. **Render:** `./render.sh` — iterates every `*.template`, calls `op inject`, writes the resolved file to `~/<name>` (mode `0600`), backs up any pre-existing file.

## On a fresh machine

```bash
brew install --cask 1password
brew install 1password-cli
op signin

# 1. Set up op plugins for supported CLIs (heroku, sentry-cli, gh)
./setup-op-plugins.sh

# 2. Render the templates that aren't covered by plugins (.npmrc, .bunfig.toml, .netrc)
cd templates && ./render.sh
```

## Adding a new secret

**Decision tree:**

1. Is the CLI in [`op plugin list`](https://developer.1password.com/docs/cli/shell-plugins/)? → Add it to the `plugins=(…)` array in `setup-op-plugins.sh`. Done.
2. Otherwise → Create the item in the `Dotfiles` vault, add a template here as `.<name>.template` referencing `{{ op://Dotfiles/<item>/<field> }}`, run `./render.sh`.

## Files in this directory

| Template | Renders to | Sources from `Dotfiles` vault |
|---|---|---|
| `.npmrc.template` | `~/.npmrc` | `GitHub PAT - npm packages`, `npmjs.com token` |
| `.bunfig.toml.template` | `~/.bunfig.toml` | `GitHub PAT - npm packages` |
| `.netrc.template` | `~/.netrc` | `Heroku CLI` (covers `git push heroku`; the `heroku` CLI itself uses `op plugin`) |

## Why not commit the rendered files?

Even with strict `.gitignore` rules, rendered secret files in the repo are one `git add -A` away from being committed. Rendered files only ever land in `$HOME` — a wayward `git add` in the dotfiles repo can never expose them.
