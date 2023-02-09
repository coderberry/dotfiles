# Load a configuration

function log () {
  if [[ $_VERBOSE -eq 1 ]]; then
    echo "$@"
  fi
}

function file-load {
  local config zshdir initfile

  ZSH_DIR=${ZSH_DIR:-${DOTDIR:-$HOME/.config}/zsh}

  for config in $@; do
    initfile=$ZSH_DIR/${config:t}.zsh

    if [ ! -f $initfile ]; then
      log "$initfile does not exist"
    fi

    if [ -f $initfile ]; then
      (( $+functions[zsh-defer] )) && zsh-defer . $initfile || . $initfile
      log "loaded $config.zsh"
    fi
  done
}

# clone a plugin, identify its init file, source it, and add it to your fpath
function plugin-load {
  local repo plugdir initfile

  ZSH_PLUGIN_DIR=${ZSH_PLUGIN_DIR:-${DOTDIR:-$HOME/.config/zsh}/plugins}

  for repo in $@; do
    plugdir=$ZSH_PLUGIN_DIR/${repo:t}

    initfile=$plugdir/${repo:t}.plugin.zsh

    if [[ ! -d $plugdir ]]; then
      log "Cloning $repo..."
      git clone -q --depth 1 --recursive --shallow-submodules https://github.com/$repo $plugdir
    fi

    if [[ ! -e $initfile ]]; then
      local -a initfiles=($plugdir/*.plugin.{z,}sh(N) $plugdir/*.{z,}sh{-theme,}(N))
      (( $#initfiles )) || { echo >&2 "No init file found '$repo'." && continue }
      ln -sf "${initfiles[1]}" "$initfile"
    fi

    fpath+=$plugdir

    (( $+functions[zsh-defer] )) && zsh-defer . $initfile || . $initfile
    log "loaded $repo"
  done
}

# clone a plugin, identify its init file, source it, and add it to your fpath
function plugin-clone {
  local repo plugdir initfile

  ZSH_PLUGINS=${ZSH_PLUGINS:-${DOTDIR:-$HOME/.config/zsh}/plugins}

  for repo in $@; do
    plugdir=$ZSH_PLUGINS/${repo:t}

    initfile=$plugdir/${repo:t}.plugin.zsh

    if [[ ! -d $plugdir ]]; then
      log "Cloning $repo..."
      git clone -q --depth 1 --recursive --shallow-submodules https://github.com/$repo $plugdir
    fi

    if [[ ! -e $initfile ]]; then
      local -a initfiles=($plugdir/*.plugin.{z,}sh(N) $plugdir/*.{z,}sh{-theme,}(N))
      (( $#initfiles )) && ln -sf "${initfiles[1]}" "$initfile"
      log "Loaded $initfile"
    fi
  done

}

# if you want to compile your plugins you may see performance gains
function plugin-compile {
  ZSH_PLUGINS=${ZSH_PLUGINS:-${DOTDIR:-$HOME/.config/zsh}/plugins}

  autoload -U zrecompile

  local f

  for f in $ZSH_PLUGINS/**/*.zsh{,-theme}(N); do
    zrecompile -pq "$f"
    log "loaded $f"
  done
}
