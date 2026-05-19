# uvenv help    — usage text
# uvenv version — print version

_uvenv_help() {
    cat <<EOF
uvenv $UVENV_VERSION — named global Python venvs (mise + uv)

Usage:
  uvenv create -n <name> [--python X.Y]   Create a named global env
  uvenv create -l <path> [--python X.Y]   Create a local venv at the given path
  uvenv activate <name|path>              Activate a global env or local path
  uvenv deactivate                        Deactivate current venv
  uvenv list                              List envs (global + local + mise)
  uvenv remove <name|path>                Delete an env (global or local)

  uvenv install [-y] <pkg>...             uv pip install (warns if no venv)
  uvenv update <pkg>... | --all           Upgrade packages in active venv
  uvenv update --self  (or self-update)   Update uvenv itself

  uvenv exec <name|path> -- <cmd>...      Run a command in an env without activating
  uvenv freeze [<name|path>]              uv pip freeze (active env, or named)

  uvenv tool install <pkg> [--python X.Y] Install uv tool (with mise switch)
  uvenv tool uninstall <pkg>              Uninstall uv tool
  uvenv tool upgrade <pkg> | --all        Upgrade uv tools
  uvenv tool list                         List uv tools

  uvenv set --python X.Y                  mise use -g python@X.Y
  uvenv status                            Show mise / uv / venv status
  uvenv doctor                            Run dependency + install sanity checks
  uvenv info                              Cheat sheet of mise + uv commands

  uvenv completions {bash|zsh}            Print shell completion script
  uvenv which                             Print storage dir
  uvenv version                           Print uvenv version
  uvenv help                              This help

Storage: \$UVENV_HOME (default ~/.uvenv)
Docs:    https://github.com/$UVENV_REPO/blob/main/USER_GUIDE.md
Repo:    https://github.com/$UVENV_REPO
EOF
}

_uvenv_version() {
    echo "uvenv $UVENV_VERSION"
}
