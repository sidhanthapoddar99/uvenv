# uvenv activate <name|path>   — activates a named global env OR a local path
# uvenv deactivate
#
# Resolution order:
#   1. $UVENV_HOME/<arg>/bin/activate    (named global env)
#   2. <arg>/bin/activate                (path, relative or absolute)
# Explicit "./foo" or "/abs/foo" effectively skips the name lookup because
# $UVENV_HOME/./foo doesn't exist.

_uvenv_activate() {
    local arg="${1:-}"
    if [ -z "$arg" ]; then
        _uvenv_log error "usage: uvenv activate <name>     # global env in \$UVENV_HOME"
        _uvenv_log error "       uvenv activate <path>     # e.g. ./venv"
        return 1
    fi

    local target script label
    if [ -f "$UVENV_HOME/$arg/bin/activate" ]; then
        target="$UVENV_HOME/$arg"
        label="'$arg'"
    elif [ -f "$arg/bin/activate" ]; then
        target="$arg"
        label="venv at $arg"
    else
        _uvenv_log error "'$arg' is not a uvenv name (in $UVENV_HOME) or a venv path"
        _uvenv_log error "       uvenv list  — to see available envs"
        return 1
    fi

    script="$target/bin/activate"
    # shellcheck disable=SC1090
    . "$script"
    _uvenv_log info "activated $label"
}

_uvenv_deactivate() {
    if [ -z "${VIRTUAL_ENV:-}" ]; then
        _uvenv_log error "no venv currently active"
        return 1
    fi
    deactivate
    _uvenv_log info "deactivated"
}
