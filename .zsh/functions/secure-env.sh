#!/usr/bin/env zsh
# =============================================================================
# secure-env.zsh
# -----------------------------------------------------------------------------
# A zsh utility function to recursively find and lock down .env files
# (or any matching pattern) by setting their permissions to 600
# (owner read/write only, no access for group or others).
#
# WHY:
#   .env files often contain secrets (API keys, DB credentials, tokens).
#   By default, files are frequently created with permissions like 644,
#   which allows any user on the system to read them. Setting 600 ensures
#   only the file owner can read/write the file.
#
# INSTALLATION:
#   1. Save this file somewhere, e.g.:
#        ~/.zsh/functions/secure-env.zsh
#
#   2. Source it from your ~/.zshrc:
#        source ~/.zsh/functions/secure-env.zsh
#
#   3. Reload your shell:
#        source ~/.zshrc
#
# USAGE:
#   secure-env [path] [options]
#
#   Arguments:
#     path                Directory to search (default: current directory ".")
#
#   Options:
#     -n, --dry-run       Preview changes without modifying any files.
#                         Shows current permissions and what they'd become.
#     -p, --pattern PAT   Filename pattern to match (default: ".env*").
#                         Use ".env" for an exact match only (no .env.local,
#                         .env.production, etc.)
#     -h, --help          Show usage information.
#
# EXAMPLES:
#   # Dry run on current directory (safe, no changes made)
#   secure-env -n
#
#   # Dry run on a specific project path
#   secure-env ~/projects/my-app -n
#
#   # Apply chmod 600 to all .env* files under a path
#   secure-env ~/projects/my-app
#
#   # Only match the exact ".env" filename
#   secure-env ~/projects/my-app -p ".env"
#
#   # Show help
#   secure-env -h
#
# NOTES:
#   - Works on both macOS (BSD stat) and Linux (GNU stat) for displaying
#     current permissions during dry runs.
#   - Does not exclude any directories by default. If you want to skip
#     directories like node_modules or .git, you can extend the `find`
#     command inside the function (e.g. add:
#       -not -path "*/node_modules/*" -not -path "*/.git/*"
#     ).
#   - Only affects regular files (-type f); symlinks and directories with
#     matching names are ignored.
# =============================================================================

secure-env() {
  emulate -L zsh
  local dry_run=false
  local target_dir="."
  local pattern=".env*"

  # ---------------------------------------------------------------------
  # Argument parsing
  # ---------------------------------------------------------------------
  while (( $# > 0 )); do
    case "$1" in
      -n|--dry-run)
        dry_run=true
        shift
        ;;
      -p|--pattern)
        pattern="$2"
        shift 2
        ;;
      -h|--help)
        cat <<'EOF'
Usage: secure-env [path] [-n|--dry-run] [-p|--pattern PATTERN]

  path              Directory to search (default: current directory)
  -n, --dry-run     Show what would change without modifying files
  -p, --pattern     Filename pattern to match (default: '.env*')
  -h, --help        Show this help message

Examples:
  secure-env -n
  secure-env ~/projects/my-app -n
  secure-env ~/projects/my-app
  secure-env ~/projects/my-app -p ".env"
EOF
        return 0
        ;;
      *)
        target_dir="$1"
        shift
        ;;
    esac
  done

  # ---------------------------------------------------------------------
  # Validate target directory
  # ---------------------------------------------------------------------
  if [[ ! -d "$target_dir" ]]; then
    echo "Error: '$target_dir' is not a valid directory" >&2
    return 1
  fi

  # ---------------------------------------------------------------------
  # Find matching files
  # ---------------------------------------------------------------------
  local -a files
  files=("${(@f)$(find "$target_dir" -type f -name "$pattern" 2>/dev/null)}")

  if (( ${#files[@]} == 0 )) || [[ -z "${files[1]}" ]]; then
    echo "No files matching '$pattern' found in '$target_dir'"
    return 0
  fi

  # ---------------------------------------------------------------------
  # Process files (dry run or apply)
  # ---------------------------------------------------------------------
  local file current_perms
  local count=0
  for file in "${files[@]}"; do
    [[ -z "$file" ]] && continue
    ((count++))
    if $dry_run; then
      # Declared above the loop: in zsh, `local` on an already-declared local
      # prints "name=value" instead of redeclaring, leaking a line per file.
      current_perms=$(stat -f "%Lp" "$file" 2>/dev/null || stat -c "%a" "$file" 2>/dev/null)
      echo "[DRY RUN] $file  (current: $current_perms -> would set: 600)"
    else
      chmod 600 "$file"
      echo "✓ chmod 600 applied: $file"
    fi
  done

  # ---------------------------------------------------------------------
  # Summary
  # ---------------------------------------------------------------------
  if $dry_run; then
    echo "\nDry run complete. ${count} file(s) would be changed. Run without -n to apply."
  else
    echo "\nDone. ${count} file(s) updated."
  fi
}
