#!/usr/bin/env bash
#
# Render every .template in this directory to its corresponding ~/.<name>
# using `op inject` (1Password CLI). Existing files are backed up.
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

cd "$(dirname "$0")"
ts=$(date +%Y%m%d-%H%M%S)
rendered=0

shopt -s nullglob
for tpl in .*.template; do
  out_name="${tpl%.template}"          # .npmrc.template → .npmrc
  out_path="$HOME/$out_name"

  if [[ -e $out_path && ! -L $out_path ]]; then
    cp "$out_path" "$out_path.bak.$ts"
    echo "  ↳ backed up $out_path → $out_path.bak.$ts"
  fi

  echo "→ Rendering $tpl → $out_path"
  op inject --in-file "$tpl" --out-file "$out_path" --force
  chmod 600 "$out_path"                # secrets shouldn't be world-readable
  rendered=$((rendered + 1))
done

if (( rendered == 0 )); then
  echo "No .template files found."
  exit 0
fi

echo ""
echo "✓ Rendered $rendered file(s). They live in \$HOME and are mode 0600."
echo "  These files are NOT symlinked back to the dotfiles repo — secrets stay local."
