#!/usr/bin/env bash
#
# Initialize 1Password `op plugin` integrations for the CLIs we use.
# Each `op plugin init` is interactive on first run (you'll pick the
# vault item and decide whether to use credentials globally / per-dir /
# only when explicitly asked). Already-initialized plugins are no-ops.
#
# Run this once per machine after you've signed in to `op`.
#
set -euo pipefail

if ! command -v op >/dev/null 2>&1; then
  echo "✗ 1Password CLI (op) not found. Install: brew install 1password-cli" >&2
  exit 1
fi

if ! op account get >/dev/null 2>&1; then
  echo "→ Not signed in to 1Password. Running: op signin"
  eval "$(op signin)"
fi

# Source the op plugin shim into the current shell so the wrapped CLIs
# work in *this* invocation. The .zshrc already sources it on every shell
# start (see the op plugin section there).
if [[ -f "$HOME/.config/op/plugins.sh" ]]; then
  # shellcheck disable=SC1091
  source "$HOME/.config/op/plugins.sh"
fi

plugins=(
  heroku       # Heroku CLI
  sentry-cli   # Sentry release management
  gh           # GitHub CLI
)

for plugin in "${plugins[@]}"; do
  if ! command -v "$plugin" >/dev/null 2>&1; then
    echo "⚠ $plugin CLI is not installed — skipping. Install via brew if you want this plugin." >&2
    continue
  fi
  echo "→ Initializing op plugin: $plugin"
  op plugin init "$plugin" || {
    echo "  (already initialized or skipped)"
  }
done

cat <<EOF

✓ Plugin setup complete.

Notes:
  - The op plugin shim is sourced at the end of .zshrc.
  - To list all configured plugins:        op plugin list
  - To re-initialize one (e.g. switch acct): op plugin init <name>
  - To remove one:                          op plugin clear <name>
EOF
