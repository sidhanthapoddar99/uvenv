# uvenv help    — usage text
# uvenv version — print version

_uvenv_help() {
    cat <<EOF
uvenv $UVENV_VERSION — named global Python venvs (mise + uv)

${_UVENV_C_BOLD}Grammar${_UVENV_C_RESET}

  uvenv tool ${_UVENV_C_CYAN}--python=3.13${_UVENV_C_RESET} install ${_UVENV_C_GREEN}dstack -U${_UVENV_C_RESET}
          └─ ${_UVENV_C_CYAN}uvenv's flags${_UVENV_C_RESET} ─┘ └─ ${_UVENV_C_GREEN}verbatim to uv${_UVENV_C_RESET} ─┘

  uvenv's own flags come BEFORE the action verb. Everything after the
  action is forwarded straight to the underlying uv / mise call.

${_UVENV_C_BOLD}Usage${_UVENV_C_RESET}

  uvenv create [--python=X.Y] -n <name>           Create a named global env
  uvenv create [--python=X.Y] -l <path>           Create a local venv at path
  uvenv activate <name|path>                      Activate an env in this shell
  uvenv deactivate                                Deactivate current venv
  uvenv list                                      List envs (global + local + mise)
  uvenv remove <name|path>                        Delete an env

  uvenv install [-y] [--] <pkg>... [uv flags]     uv pip install (warns if no venv)
  uvenv update <pkg>... | --all                   Upgrade packages in active venv
  uvenv update --self  (or self-update)           Update uvenv itself

  uvenv exec <name|path> -- <cmd>...              Run a command in an env without activating
  uvenv freeze [<name|path>]                      uv pip freeze (active or named)

  uvenv tool [--python=X.Y] install <pkg> [...]   Install a uv tool (passthrough)
  uvenv tool uninstall <pkg>                      Uninstall a uv tool
  uvenv tool upgrade <pkg> | --all                Upgrade uv tools
  uvenv tool list                                 List uv tools

  uvenv set --python=X.Y                          mise use -g python@X.Y
  uvenv status                                    Show mise / uv / venv state
  uvenv doctor                                    Run dependency + install sanity checks
  uvenv info                                      Cheat sheet of mise + uv commands

  uvenv completions {bash|zsh}                    Print shell completion script
  uvenv which                                     Print storage dir (\$UVENV_HOME)
  uvenv version                                   Print uvenv version
  uvenv help                                      This help

Storage: \$UVENV_HOME (default ~/.uvenv)
Docs:    https://github.com/$UVENV_REPO/blob/main/USER_GUIDE.md
Repo:    https://github.com/$UVENV_REPO
EOF
}

_uvenv_version() {
    printf 'uvenv %s\n' "$UVENV_VERSION"
}
