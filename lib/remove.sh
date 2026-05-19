# uvenv remove <name|path>
#
# Resolves the same way as activate: tries $UVENV_HOME/<arg> first, then <arg>
# as a path. Refuses if the target is the currently-active venv.

_uvenv_remove() {
    local arg="${1:-}"
    if [ -z "$arg" ]; then
        _uvenv_log error "usage: uvenv remove <name>      # global env"
        _uvenv_log error "       uvenv remove <path>      # e.g. ./venv"
        return 1
    fi

    local target
    if [ -d "$UVENV_HOME/$arg" ] && [ -f "$UVENV_HOME/$arg/pyvenv.cfg" ]; then
        target="$UVENV_HOME/$arg"
    elif [ -d "$arg" ] && [ -f "$arg/pyvenv.cfg" ]; then
        target="$arg"
    else
        _uvenv_log error "'$arg' is not a uvenv name (in $UVENV_HOME) or a venv path"
        return 1
    fi

    # Compare resolved paths so ./venv == /abs/cwd/venv == $VIRTUAL_ENV.
    local target_abs venv_abs
    target_abs="$(cd "$target" 2>/dev/null && pwd)"
    venv_abs="${VIRTUAL_ENV:+$(cd "$VIRTUAL_ENV" 2>/dev/null && pwd)}"
    if [ -n "$venv_abs" ] && [ "$target_abs" = "$venv_abs" ]; then
        _uvenv_log error "'$arg' is currently active — deactivate first"
        return 1
    fi

    rm -rf "$target"
    _uvenv_log info "removed $target"
}
