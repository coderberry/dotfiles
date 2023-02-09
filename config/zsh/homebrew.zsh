if [ -d /opt/homebrew/bin ]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
fi

if command -v brew &> /dev/null; then
  export BREW_PREFIX=$(brew --prefix)
fi
