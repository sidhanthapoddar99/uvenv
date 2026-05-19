# uvenv freeze [<name|path>]
#
# With no arg, freeze the currently-active venv.
# With an arg, freeze that env without activating in this shell.

_uvenv_freeze() {
    local arg="${1:-}"

    if [ -z "$arg" ]; then
        if [ -z "${VIRTUAL_ENV:-}" ]; then
            _uvenv_log error "no venv active. usage: uvenv freeze [<name|path>]"
            return 1
        fi
        uv pip freeze
        return $?
    fi

    local target
    if [ -d "$UVENV_HOME/$arg" ] && [ -f "$UVENV_HOME/$arg/bin/activate" ]; then
        target="$UVENV_HOME/$arg"
    elif [ -d "$arg" ] && [ -f "$arg/bin/activate" ]; then
        target="$arg"
    else
        _uvenv_log error "'$arg' is not a uvenv name or a venv path"
        return 1
    fi

    (
        # shellcheck disable=SC1091
        . "$target/bin/activate"
        uv pip freeze
    )
}
